import React, { useState, useEffect, useCallback } from 'react';
import { Table, Button, Space, Card, message, Popconfirm, Tag, Select } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import { Input } from 'antd';
import { useArtist } from '../contexts/ArtistContext';

const { Search } = Input;
const { Option } = Select;

const ShopsPage = () => {
  const [shops, setShops] = useState([]);
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [selectedArtist, setSelectedArtist] = useState('');
  const navigate = useNavigate();
  const { getArtistQueryParam } = useArtist();

  const fetchArtists = useCallback(async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  }, []);

  const fetchShops = useCallback(async (artistId = '') => {
    setLoading(true);
    try {
      const artistFilter = getArtistQueryParam();
      const queryParams = new URLSearchParams();
      
      // Use artist filter from context if available, otherwise use local filter
      const filterArtistId = artistFilter.artist_id || artistId;
      if (filterArtistId) {
        queryParams.append('artist_id', filterArtistId);
      }
      
      const url = queryParams.toString() 
        ? `/api/v1/music/shops?${queryParams.toString()}`
        : '/api/v1/music/shops';
      
      const response = await apiService.get(url);
      setShops(response.data || []);
    } catch (error) {
      message.error('Failed to fetch shops');
    } finally {
      setLoading(false);
    }
  }, [getArtistQueryParam]);

  useEffect(() => {
    fetchArtists();
    fetchShops();
  }, [fetchArtists, fetchShops]);

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
      title: 'Artists',
      key: 'artists',
      render: (_, record) => {
        if (record.artists && record.artists.length > 0) {
          return record.artists.map(artist => (
            <Tag key={artist.artist_id} style={{ marginBottom: 4 }}>
              {artist.name}
            </Tag>
          ));
        }
        return record.primaryArtist?.name ? (
          <Tag>{record.primaryArtist.name}</Tag>
        ) : '-';
      },
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
      render: (_, record) => {
        if (record.is_deleted) {
          return <Tag color="red">Deleted</Tag>;
        }
        return record.is_active ? <Tag color="green">Active</Tag> : <Tag color="orange">Inactive</Tag>;
      },
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
    <Card title="Shops">
      <div
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          gap: 12,
          marginBottom: 16,
          alignItems: 'center'
        }}
      >
        <Search
          placeholder="Search shops..."
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          onSearch={() => fetchShops(selectedArtist)}
          style={{ flex: '1 1 240px', minWidth: 200 }}
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
          style={{ flex: '1 1 200px', minWidth: 180 }}
        >
          {artists.map((artist) => (
            <Option key={artist.artist_id} value={artist.artist_id}>
              {artist.name}
            </Option>
          ))}
        </Select>
        <div style={{ marginLeft: 'auto' }}>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/shops/create')}
          >
            Add Shop
          </Button>
        </div>
      </div>
      <Table
        columns={columns}
        dataSource={shops}
        loading={loading}
        rowKey="shop_id"
        scroll={{ x: 'max-content' }}
      />
    </Card>
  );
};

export default ShopsPage;

