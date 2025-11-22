import React, { useState, useEffect } from 'react';
import { Form, Input, Button, Card, message, Switch, Select, Tag, Space } from 'antd';
import { SaveOutlined, ArrowLeftOutlined, PlusOutlined, CloseOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { apiService } from '../services/api';
import ImageUpload from '../components/ImageUpload';

const { Option } = Select;

const ArtistFormPage = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [imageUrl, setImageUrl] = useState('');
  const [selectedBrandings, setSelectedBrandings] = useState([]);
  const [selectedShopId, setSelectedShopId] = useState(null);
  const [availableBrandings, setAvailableBrandings] = useState([]);
  const [availableShops, setAvailableShops] = useState([]);
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = !!id;

  useEffect(() => {
    fetchBrandings();
    fetchShops();
    if (isEdit) {
      fetchArtist();
    }
  }, [id]);

  const fetchBrandings = async () => {
    try {
      const response = await apiService.get('/api/v1/music/brandings?limit=1000');
      setAvailableBrandings(response.data || []);
    } catch (error) {
      console.error('Failed to fetch brandings');
    }
  };

  const fetchShops = async () => {
    try {
      const response = await apiService.get('/api/v1/music/shops?limit=1000');
      setAvailableShops(response.data || []);
    } catch (error) {
      console.error('Failed to fetch shops');
    }
  };

  const fetchArtist = async () => {
    try {
      const response = await apiService.get(`/api/v1/music/artists/${id}`);
      const artist = response.data;
      form.setFieldsValue(artist);
      if (artist.image_url) {
        setImageUrl(artist.image_url);
      }
      // Set brandings and shop from the response
      if (artist.brandings) {
        setSelectedBrandings(artist.brandings.map(b => b.branding_id));
      }
      if (artist.shop) {
        setSelectedShopId(artist.shop.shop_id);
        form.setFieldsValue({ shop_id: artist.shop.shop_id });
      } else if (artist.shop_id) {
        setSelectedShopId(artist.shop_id);
        form.setFieldsValue({ shop_id: artist.shop_id });
      }
    } catch (error) {
      message.error('Failed to fetch artist');
      navigate('/artists');
    }
  };

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const data = {
        ...values,
        brandings: selectedBrandings,
        shop_id: selectedShopId || null
      };

      if (isEdit) {
        await apiService.put(`/api/v1/music/artists/${id}`, data);
        message.success('Artist updated successfully');
      } else {
        await apiService.post('/api/v1/music/artists', data);
        message.success('Artist created successfully');
      }
      navigate('/artists');
    } catch (error) {
      message.error(isEdit ? 'Failed to update artist' : 'Failed to create artist');
    } finally {
      setLoading(false);
    }
  };

  const addBranding = (brandingId) => {
    if (brandingId && !selectedBrandings.includes(brandingId)) {
      setSelectedBrandings([...selectedBrandings, brandingId]);
    }
  };

  const removeBranding = (brandingId) => {
    setSelectedBrandings(selectedBrandings.filter(id => id !== brandingId));
  };

  const getBrandingName = (brandingId) => {
    const branding = availableBrandings.find(b => b.branding_id === brandingId);
    return branding ? branding.branding_name : '';
  };

  return (
    <Card
      title={isEdit ? 'Edit Artist' : 'Create Artist'}
      extra={
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/artists')}>
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
          name="name"
          label="Artist Name"
          rules={[{ required: true, message: 'Please enter artist name' }]}
        >
          <Input placeholder="Enter artist name" />
        </Form.Item>

        <Form.Item name="bio" label="Biography">
          <Input.TextArea rows={4} placeholder="Enter biography" />
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

        <Form.Item name="image_url" label="Artist Image" hidden>
          <Input />
        </Form.Item>

        <Form.Item label="Artist Image">
          <ImageUpload
            folder="artists"
            value={imageUrl}
            onChange={(url) => {
              setImageUrl(url);
              form.setFieldsValue({ image_url: url });
            }}
          />
        </Form.Item>

        <Form.Item label="Brandings">
          <Space direction="vertical" style={{ width: '100%' }}>
            <Select
              placeholder="Add a branding"
              showSearch
              filterOption={(input, option) =>
                (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
              }
              onChange={addBranding}
              value={null}
              style={{ width: '100%' }}
            >
              {availableBrandings
                .filter(b => !selectedBrandings.includes(b.branding_id))
                .map(branding => (
                  <Option key={branding.branding_id} value={branding.branding_id}>
                    {branding.branding_name}
                  </Option>
                ))}
            </Select>
            <div>
              {selectedBrandings.map(brandingId => (
                <Tag
                  key={brandingId}
                  closable
                  onClose={() => removeBranding(brandingId)}
                  style={{ marginBottom: 8 }}
                >
                  {getBrandingName(brandingId)}
                </Tag>
              ))}
            </div>
          </Space>
        </Form.Item>

        <Form.Item
          name="shop_id"
          label="Shop"
        >
          <Select
            placeholder="Select a shop"
            showSearch
            filterOption={(input, option) =>
              (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
            }
            onChange={(value) => {
              setSelectedShopId(value);
              form.setFieldsValue({ shop_id: value });
            }}
            value={selectedShopId}
            allowClear
            style={{ width: '100%' }}
          >
            {availableShops.map(shop => (
              <Option key={shop.shop_id} value={shop.shop_id}>
                {shop.shop_name}
              </Option>
            ))}
          </Select>
        </Form.Item>

        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} icon={<SaveOutlined />}>
            {isEdit ? 'Update Artist' : 'Create Artist'}
          </Button>
        </Form.Item>
      </Form>
    </Card>
  );
};

export default ArtistFormPage;
