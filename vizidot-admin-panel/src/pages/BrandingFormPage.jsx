import React, { useState, useEffect, useCallback } from 'react';
import { Form, Input, Button, Card, message, Select, Switch, Tag, Space, ColorPicker } from 'antd';
import { SaveOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { apiService } from '../services/api';
import ImageUpload from '../components/ImageUpload';

const { Option } = Select;

const BrandingFormPage = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [imageUrl, setImageUrl] = useState('');
  const [selectedArtists, setSelectedArtists] = useState([]);
  const [availableArtists, setAvailableArtists] = useState([]);
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = !!id;

  const fetchArtists = useCallback(async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setAvailableArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  }, []);

  const fetchBranding = useCallback(async () => {
    try {
      const response = await apiService.get(`/api/v1/music/brandings/${id}`);
      const branding = response.data;
      form.setFieldsValue(branding);
      if (branding.logo_url) {
        setImageUrl(branding.logo_url);
      }
      if (branding.background_color) {
        form.setFieldsValue({ background_color: branding.background_color });
      } else {
        form.setFieldsValue({ background_color: null });
      }
      // Set artists from the response
      if (branding.artists) {
        setSelectedArtists(branding.artists.map(a => a.artist_id));
      }
    } catch (error) {
      message.error('Failed to fetch branding');
      navigate('/brandings');
    }
  }, [form, id, navigate]);

  useEffect(() => {
    fetchArtists();
  }, [fetchArtists]);

  useEffect(() => {
    if (isEdit) {
      fetchBranding();
    }
  }, [fetchBranding, isEdit]);

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const data = {
        ...values,
        logo_url: imageUrl,
        artists: selectedArtists
      };

      if (isEdit) {
        await apiService.put(`/api/v1/music/brandings/${id}`, data);
        message.success('Branding updated successfully');
      } else {
        await apiService.post('/api/v1/music/brandings', data);
        message.success('Branding created successfully');
      }
      navigate('/brandings');
    } catch (error) {
      message.error(isEdit ? 'Failed to update branding' : 'Failed to create branding');
    } finally {
      setLoading(false);
    }
  };

  const addArtist = (artistId) => {
    if (artistId && !selectedArtists.includes(artistId)) {
      setSelectedArtists([...selectedArtists, artistId]);
    }
  };

  const removeArtist = (artistId) => {
    setSelectedArtists(selectedArtists.filter(id => id !== artistId));
  };

  const getArtistName = (artistId) => {
    const artist = availableArtists.find(a => a.artist_id === artistId);
    return artist ? artist.name : '';
  };


  return (
    <Card
      title={isEdit ? 'Edit Branding' : 'Create Branding'}
      extra={
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/brandings')}>
          Back
        </Button>
      }
    >
      <Form
        form={form}
        layout="vertical"
        onFinish={onFinish}
      >
        <Form.Item
          name="branding_name"
          label="Branding Name"
          rules={[{ required: true, message: 'Please enter branding name' }]}
        >
          <Input placeholder="Enter branding name" />
        </Form.Item>

        <Form.Item name="tagline" label="Tagline">
          <Input placeholder="Enter tagline" />
        </Form.Item>

        <Form.Item
          name="background_color"
          label="Background Color"
          rules={[
            {
              pattern: /^#[0-9A-Fa-f]{6}$/,
              message: 'Please enter a valid hex color (e.g., #FF5733)'
            }
          ]}
          getValueFromEvent={(color) => {
            if (color) {
              return typeof color === 'string' ? color : color.toHexString();
            }
            return null;
          }}
        >
          <ColorPicker
            showText
            format="hex"
          />
        </Form.Item>

        <Form.Item
          name="is_active"
          label="Status"
          valuePropName="checked"
          initialValue={true}
        >
          <Switch
            checkedChildren="Active"
            unCheckedChildren="Inactive"
          />
        </Form.Item>

        <Form.Item name="logo_url" label="Logo URL" hidden>
          <Input />
        </Form.Item>

        <Form.Item label="Logo">
          <ImageUpload
            folder="brandings"
            value={imageUrl}
            onChange={(url) => {
              setImageUrl(url);
              form.setFieldsValue({ logo_url: url });
            }}
          />
        </Form.Item>

        <Form.Item label="Artists">
          <Space direction="vertical" style={{ width: '100%' }}>
            <Select
              placeholder="Add an artist"
              showSearch
              filterOption={(input, option) =>
                (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
              }
              onChange={addArtist}
              value={null}
              style={{ width: '100%' }}
            >
              {availableArtists
                .filter(a => !selectedArtists.includes(a.artist_id))
                .map(artist => (
                  <Option key={artist.artist_id} value={artist.artist_id}>
                    {artist.name}
                  </Option>
                ))}
            </Select>
            <div>
              {selectedArtists.map(artistId => (
                <Tag
                  key={artistId}
                  closable
                  onClose={() => removeArtist(artistId)}
                  style={{ marginBottom: 8 }}
                >
                  {getArtistName(artistId)}
                </Tag>
              ))}
            </div>
          </Space>
        </Form.Item>

        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} icon={<SaveOutlined />}>
            {isEdit ? 'Update Branding' : 'Create Branding'}
          </Button>
        </Form.Item>
      </Form>
    </Card>
  );
};

export default BrandingFormPage;
