import React, { useState, useEffect } from 'react';
import { Form, Input, Button, Card, message, Select, Tag, Space } from 'antd';
import { SaveOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { apiService } from '../services/api';

const { Option } = Select;

const ShopFormPage = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [selectedArtists, setSelectedArtists] = useState([]);
  const [availableArtists, setAvailableArtists] = useState([]);
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = !!id;

  useEffect(() => {
    fetchArtists();
    if (isEdit) {
      fetchShop();
    }
  }, [id]);

  const fetchArtists = async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setAvailableArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  };

  const fetchShop = async () => {
    try {
      const response = await apiService.get(`/api/v1/music/shops/${id}`);
      const shop = response.data;
      form.setFieldsValue(shop);
      // Set artists from the response
      if (shop.artists) {
        setSelectedArtists(shop.artists.map(a => a.artist_id));
      }
    } catch (error) {
      message.error('Failed to fetch shop');
      navigate('/shops');
    }
  };

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const data = {
        ...values,
        artists: selectedArtists
      };

      if (isEdit) {
        await apiService.put(`/api/v1/music/shops/${id}`, data);
        message.success('Shop updated successfully');
      } else {
        await apiService.post('/api/v1/music/shops', data);
        message.success('Shop created successfully');
      }
      navigate('/shops');
    } catch (error) {
      message.error(isEdit ? 'Failed to update shop' : 'Failed to create shop');
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
      title={isEdit ? 'Edit Shop' : 'Create Shop'}
      extra={
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/shops')}>
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
          name="shop_name"
          label="Shop Name"
          rules={[{ required: true, message: 'Please enter shop name' }]}
        >
          <Input placeholder="Enter shop name" />
        </Form.Item>

        <Form.Item
          name="shop_url"
          label="Shop URL"
          rules={[
            { required: true, message: 'Please enter shop URL' },
            { type: 'url', message: 'Please enter a valid URL' }
          ]}
        >
          <Input placeholder="https://example.com" />
        </Form.Item>

        <Form.Item name="description" label="Description">
          <Input.TextArea rows={4} placeholder="Enter description" />
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
            {isEdit ? 'Update Shop' : 'Create Shop'}
          </Button>
        </Form.Item>
      </Form>
    </Card>
  );
};

export default ShopFormPage;

