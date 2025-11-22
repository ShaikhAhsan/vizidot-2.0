import React, { useState, useEffect } from 'react';
import { Table, Button, Space, Card, message, Popconfirm, Tag, Select } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import { Input } from 'antd';

const { Search } = Input;
const { Option } = Select;

const ShopsPage = () => {
  const [shops, setShops] = useState([]);
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [selectedArtist, setSelectedArtist] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    fetchArtists();
    fetchShops();
  }, []);

  const fetchArtists = async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  };

  const fetchShops = async (artistId = '') => {
    setLoading(true);
    try {
      let url = '/api/v1/music/shops';
      if (artistId) url += `?artist_id=${artistId}`;
      
      const response = await apiService.get(url);
      setShops(response.data || []);
    } catch (error) {
      message.error('Failed to fetch shops');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    try {
      await apiService.delete(`/api/v1/music/shops/${id}`);
      message.success('Shop deleted successfully');
      fetchShops(selectedArtist);
    } catch (error) {
      message.error('Failed to delete shop');
    }
  };

  const columns = [
    {
      title: 'Shop Name',
      dataIndex: 'shop_name',
      key: 'shop_name',
    },
    {
      title: 'Artist',
      key: 'artist',
      render: (_, record) => record.artist?.name || '-',
    },
    {
      title: 'Branding',
      key: 'branding',
      render: (_, record) => record.branding?.branding_name || '-',
    },
    {
      title: 'Shop URL',
      dataIndex: 'shop_url',
      key: 'shop_url',
      render: (url) => url ? (
        <a href={url} target="_blank" rel="noopener noreferrer">
          {url.length > 30 ? `${url.substring(0, 30)}...` : url}
        </a>
      ) : '-',
    },
    {
      title: 'Status',
      key: 'status',
      render: (_, record) => (
        record.is_deleted ? <Tag color="red">Deleted</Tag> : <Tag color="green">Active</Tag>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            onClick={() => navigate(`/shops/edit/${record.shop_id}`)}
            disabled={record.is_deleted}
          >
            Edit
          </Button>
          <Popconfirm
            title="Delete this shop?"
            onConfirm={() => handleDelete(record.shop_id)}
          >
            <Button icon={<DeleteOutlined />} danger disabled={record.is_deleted}>
              Delete
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <Card
      title="Shops"
      extra={
        <Space>
          <Search
            placeholder="Search shops..."
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onSearch={() => fetchShops(selectedArtist)}
            style={{ width: 250 }}
            allowClear
          />
          <Select
            placeholder="Filter by Artist"
            value={selectedArtist}
            onChange={(value) => {
              setSelectedArtist(value);
              fetchShops(value);
            }}
            allowClear
            style={{ width: 200 }}
          >
            {artists.map(artist => (
              <Option key={artist.artist_id} value={artist.artist_id}>
                {artist.name}
              </Option>
            ))}
          </Select>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/shops/create')}
          >
            Add Shop
          </Button>
        </Space>
      }
    >
      <Table
        columns={columns}
        dataSource={shops}
        loading={loading}
        rowKey="shop_id"
      />
    </Card>
  );
};

export default ShopsPage;

