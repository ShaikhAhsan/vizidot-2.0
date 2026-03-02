import React, { useState, useEffect, useCallback } from 'react';
import { Form, Input, Select, Button, Space, message } from 'antd';
import { apiService, adminAPI } from '../services/api';
import { useFirebaseAuth } from '../contexts/FirebaseAuthContext';

const { Option } = Select;
const UserForm = ({ initialValues, onSubmit, loading, isEdit, onCancel }) => {
  const [form] = Form.useForm();
  const [availableArtists, setAvailableArtists] = useState([]);
  const [loadingArtists, setLoadingArtists] = useState(false);
  const [availableRoles, setAvailableRoles] = useState([]);
  const [loadingRoles, setLoadingRoles] = useState(false);
  const { isSuperAdmin } = useFirebaseAuth();

  const fetchArtists = useCallback(async () => {
    setLoadingArtists(true);
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      if (response.success) {
        setAvailableArtists(response.data || []);
      }
    } catch (error) {
      console.error('Failed to fetch artists');
    } finally {
      setLoadingArtists(false);
    }
  }, []);

  const fetchRoles = useCallback(async () => {
    setLoadingRoles(true);
    try {
      const response = await adminAPI.getRoles(true);
      if (response.success) {
        setAvailableRoles(response.data || []);
      }
    } catch (error) {
      console.error('Failed to fetch roles:', error);
      message.error('Failed to load roles. Using default roles.');
    } finally {
      setLoadingRoles(false);
    }
  }, []);

  const fetchAssignedArtists = useCallback(async (userId) => {
    if (!userId) return;
    try {
      const response = await apiService.get(`/api/v1/admin/users/${userId}/artists`);
      const raw = response && (response.success ? response.data : response);
      const list = Array.isArray(raw) ? raw : ((raw && (raw.artists || raw.data || raw.data?.artists)) || []);
      const ids = list
        .map((a) => {
          const id = a && (a.artist_id ?? a.id ?? a);
          return id != null ? String(id) : null;
        })
        .filter(Boolean);
      form.setFieldsValue({ artist_ids: ids });
      setTimeout(() => form.setFieldsValue({ artist_ids: ids }), 0);
    } catch (error) {
      console.error('Failed to fetch assigned artists', error);
      form.setFieldsValue({ artist_ids: [] });
    }
  }, [form]);

  useEffect(() => {
    fetchArtists();
    fetchRoles();
  }, [fetchArtists, fetchRoles]);

  useEffect(() => {
    if (isEdit && initialValues?.id) {
      fetchAssignedArtists(initialValues.id);
    } else {
      form.setFieldsValue({ artist_ids: [] });
    }
  }, [fetchAssignedArtists, initialValues?.id, isEdit]);

  const handleSubmit = async (values) => {
    try {
      console.log('Form values on submit:', values);
      console.log('artist_ids from form:', values.artist_ids);
      
      // Submit user data first
      const userData = {
        first_name: values.first_name,
        last_name: values.last_name,
        phone: values.phone,
        role: values.role,
        is_active: values.is_active
      };

      let userId = initialValues?.id;
      
      if (isEdit && userId) {
        await apiService.put(`/api/v1/admin/users/${userId}`, userData);
      } else {
        // Create new user
        const createResponse = await apiService.post('/api/v1/admin/users', {
          ...userData,
          email: values.email // Email is required for creation
        });
        userId = createResponse.data?.id;
        if (!userId) {
          throw new Error('Failed to create user');
        }
      }

      if (isSuperAdmin() && userId) {
        try {
          let artistIds = values.artist_ids;
          if (artistIds === undefined || artistIds === null) {
            artistIds = form.getFieldValue('artist_ids');
          }
          artistIds = Array.isArray(artistIds) ? artistIds : (artistIds != null ? [artistIds] : []);
          const toSend = artistIds.map((id) => {
            const n = Number(id);
            return Number.isFinite(n) ? n : id;
          });
          await apiService.post(`/api/v1/admin/users/${userId}/artists`, {
            artist_ids: toSend
          });
        } catch (artistError) {
          console.error('Failed to assign artists', artistError);
          message.warning('User updated but failed to assign artists');
        }
      }

      message.success(isEdit ? 'User updated successfully' : 'User created successfully');
      
      // Call onSubmit with success flag - GenericCRUDTable's handleUpdate will see this
      // and make its own API call, but we need to prevent that duplicate call
      // Instead, we'll pass a special flag to indicate we've already handled it
      // Actually, let's just pass the data and let GenericCRUDTable handle the refresh
      // But we need to make sure it doesn't make another API call
      // The issue is handleUpdate will make another PUT request
      // So we need to modify the approach - pass a success indicator
      onSubmit({ success: true, id: userId });
    } catch (error) {
      console.error('User update error:', error);
      message.error(error.message || (isEdit ? 'Failed to update user' : 'Failed to create user'));
      // Don't call onSubmit on error
    }
  };

  return (
    <Form
      form={form}
      layout="vertical"
      onFinish={handleSubmit}
      initialValues={{
        ...(initialValues || {}),
        is_active: initialValues?.is_active !== undefined ? initialValues.is_active : true,
        artist_ids: isEdit
          ? []
          : (() => {
              const list = initialValues?.assignedArtists || initialValues?.assigned_artists || [];
              return list
                .map((a) => {
                  const id = a?.artist_id ?? a?.id ?? a;
                  return id != null ? String(id) : null;
                })
                .filter(Boolean);
            })()
      }}
    >
      <Form.Item
        name="first_name"
        label="First Name"
        rules={[{ required: true, message: 'Please enter first name' }]}
      >
        <Input placeholder="Enter first name" />
      </Form.Item>

      <Form.Item
        name="last_name"
        label="Last Name"
        rules={[{ required: true, message: 'Please enter last name' }]}
      >
        <Input placeholder="Enter last name" />
      </Form.Item>

      <Form.Item
        name="email"
        label="Email"
        rules={[{ required: true, message: 'Please enter email' }]}
      >
        <Input placeholder="Enter email" disabled={isEdit} />
      </Form.Item>

      <Form.Item name="phone" label="Phone">
        <Input placeholder="Enter phone number" />
      </Form.Item>

      <Form.Item
        name="role"
        label="Role"
        rules={[{ required: true, message: 'Please select role' }]}
      >
        <Select 
          placeholder="Select role"
          loading={loadingRoles}
          showSearch
          filterOption={(input, option) =>
            (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
          }
        >
          {availableRoles.map(role => (
            <Option key={role.name} value={role.name}>
              {role.display_name || role.name}
            </Option>
          ))}
        </Select>
      </Form.Item>

      <Form.Item
        name="is_active"
        label="Active"
        rules={[{ required: true, message: 'Please select status' }]}
      >
        <Select placeholder="Select status">
          <Option value={true}>Active</Option>
          <Option value={false}>Inactive</Option>
        </Select>
      </Form.Item>

      {isSuperAdmin() && isEdit && (
        <>
          <Form.Item
            name="artist_ids"
            label="Assigned Artists"
            getValueFromEvent={(value) => {
              if (value == null || value === undefined) return [];
              const arr = Array.isArray(value) ? value : [value];
              return arr.map((id) => (id != null ? String(id) : null)).filter(Boolean);
            }}
          >
            <Select
              mode="multiple"
              placeholder="Select artists to assign"
              loading={loadingArtists}
              showSearch
              allowClear
              optionFilterProp="label"
              filterOption={(input, option) =>
                (option?.label ?? option?.children ?? '')
                  .toString()
                  .toLowerCase()
                  .includes((input || '').toLowerCase())
              }
            >
              {availableArtists.map(artist => (
                <Option key={artist.artist_id} value={String(artist.artist_id)} label={artist.name}>
                  {artist.name}
                </Option>
              ))}
            </Select>
          </Form.Item>
          <div style={{ marginTop: -16, marginBottom: 16, fontSize: '12px', color: '#999' }}>
            Select one or more artists to assign to this user. Users with assigned artists can access the admin panel.
          </div>
        </>
      )}

      <Form.Item>
        <Space>
          <Button type="primary" htmlType="submit" loading={loading}>
            {isEdit ? 'Update' : 'Create'}
          </Button>
        </Space>
      </Form.Item>
    </Form>
  );
};

export default UserForm;

