import React, { useState, useEffect } from 'react';
import { Form, Input, Button, Card, message, Select, Switch } from 'antd';
import { SaveOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { apiService } from '../services/api';
import ImageUpload from '../components/ImageUpload';

const { TextArea } = Input;
const { Option } = Select;

const BrandingFormPage = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [imageUrl, setImageUrl] = useState('');
  const [artists, setArtists] = useState([]);
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = !!id;

  useEffect(() => {
    fetchArtists();
    if (isEdit) {
      fetchBranding();
    }
  }, [id]);

  const fetchArtists = async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  };

  const fetchBranding = async () => {
    try {
      const response = await apiService.get(`/api/v1/music/brandings/${id}`);
      const branding = response.data;
      form.setFieldsValue(branding);
      if (branding.logo_url) {
        setImageUrl(branding.logo_url);
      }
    } catch (error) {
      message.error('Failed to fetch branding');
      navigate('/brandings');
    }
  };

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const data = {
        ...values,
        logo_url: imageUrl
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
          name="artist_id"
          label="Artist"
          rules={[{ required: true, message: 'Please select an artist' }]}
        >
          <Select
            placeholder="Select an artist"
            showSearch
            filterOption={(input, option) =>
              (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
            }
            disabled={isEdit}
          >
            {artists.map(artist => (
              <Option key={artist.artist_id} value={artist.artist_id}>
                {artist.name}
              </Option>
            ))}
          </Select>
        </Form.Item>

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

