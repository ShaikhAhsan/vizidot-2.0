import React, { useState, useEffect } from 'react';
import { Form, Input, Select, Button, Space, message, Tag } from 'antd';
import { apiService } from '../services/api';
import { useFirebaseAuth } from '../contexts/FirebaseAuthContext';

const { Option } = Select;
const { TextArea } = Input;

const UserForm = ({ initialValues, onSubmit, loading, isEdit, onCancel }) => {
  const [form] = Form.useForm();
  const [availableArtists, setAvailableArtists] = useState([]);
  const [assignedArtists, setAssignedArtists] = useState([]);
  const [loadingArtists, setLoadingArtists] = useState(false);
  const { isSuperAdmin } = useFirebaseAuth();

  useEffect(() => {
    fetchArtists();
    if (isEdit && initialValues?.id) {
      fetchAssignedArtists(initialValues.id);
    }
  }, [isEdit, initialValues?.id]);

  const fetchArtists = async () => {
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
  };

  const fetchAssignedArtists = async (userId) => {
    try {
      const response = await apiService.get(`/api/v1/admin/users/${userId}/artists`);
      if (response.success) {
        const artistIds = (response.data || []).map(a => a.artist_id);
        setAssignedArtists(artistIds);
        form.setFieldsValue({ artist_ids: artistIds });
      }
    } catch (error) {
      console.error('Failed to fetch assigned artists');
    }
  };

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

      // Then assign artists (only super admin can do this)
      if (isSuperAdmin() && userId) {
        try {
          // Get artist_ids from form values - try multiple ways to get the value
          let artistIds = values.artist_ids;
          
          // If not in values, try getting from form directly
          if (artistIds === undefined || artistIds === null) {
            artistIds = form.getFieldValue('artist_ids');
          }
          
          // Ensure it's an array
          artistIds = Array.isArray(artistIds) ? artistIds : (artistIds ? [artistIds] : []);
          
          console.log('Final artist_ids being submitted:', artistIds);
          
          await apiService.post(`/api/v1/admin/users/${userId}/artists`, {
            artist_ids: artistIds
          });
        } catch (artistError) {
          console.error('Failed to assign artists:', artistError);
          // Don't fail the whole operation if artist assignment fails
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
        artist_ids: initialValues?.assignedArtists ? initialValues.assignedArtists.map(a => a.artist_id) : []
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
        <Select placeholder="Select role">
          <Option value="customer">Customer</Option>
          <Option value="super_admin">Super Admin</Option>
          <Option value="system_admin">System Admin</Option>
          <Option value="business_owner">Business Owner</Option>
          <Option value="business_admin">Business Admin</Option>
          <Option value="business_manager">Business Manager</Option>
          <Option value="business_staff">Business Staff</Option>
          <Option value="business_rider">Business Rider</Option>
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
        <Form.Item
          name="artist_ids"
          label="Assigned Artists"
          getValueFromEvent={(value) => {
            // Ensure we always return an array
            if (!value) return [];
            return Array.isArray(value) ? value : [value];
          }}
        >
          <Select
            mode="multiple"
            placeholder="Select artists to assign"
            loading={loadingArtists}
            showSearch
            allowClear
            value={form.getFieldValue('artist_ids') || []}
            onChange={(value) => {
              console.log('Artist selection changed:', value);
              form.setFieldsValue({ artist_ids: value || [] });
            }}
            filterOption={(input, option) =>
              (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
            }
          >
            {availableArtists.map(artist => (
              <Option key={artist.artist_id} value={artist.artist_id}>
                {artist.name}
              </Option>
            ))}
          </Select>
          <div style={{ marginTop: 8, fontSize: '12px', color: '#999' }}>
            Select one or more artists to assign to this user. Users with assigned artists can access the admin panel.
          </div>
        </Form.Item>
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

