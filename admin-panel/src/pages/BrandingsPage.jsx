import React, { useState, useEffect } from 'react';
import { Table, Button, Space, Card, message, Popconfirm, Tag, Select } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import { Input } from 'antd';

const { Search } = Input;
const { Option } = Select;

const BrandingsPage = () => {
  const [brandings, setBrandings] = useState([]);
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [selectedArtist, setSelectedArtist] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    fetchArtists();
    fetchBrandings();
  }, []);

  const fetchArtists = async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  };

  const fetchBrandings = async (artistId = '') => {
    setLoading(true);
    try {
      let url = '/api/v1/music/brandings';
      if (artistId) url += `?artist_id=${artistId}`;
      
      const response = await apiService.get(url);
      setBrandings(response.data || []);
    } catch (error) {
      message.error('Failed to fetch brandings');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    try {
      await apiService.delete(`/api/v1/music/brandings/${id}`);
      message.success('Branding deleted successfully');
      fetchBrandings(selectedArtist);
    } catch (error) {
      message.error('Failed to delete branding');
    }
  };

  const columns = [
    {
      title: 'Branding Name',
      dataIndex: 'branding_name',
      key: 'branding_name',
    },
    {
      title: 'Artist',
      key: 'artist',
      render: (_, record) => record.artist?.name || '-',
    },
    {
      title: 'Tagline',
      dataIndex: 'tagline',
      key: 'tagline',
      render: (tagline) => tagline || '-',
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
            onClick={() => navigate(`/brandings/edit/${record.branding_id}`)}
            disabled={record.is_deleted}
          >
            Edit
          </Button>
          <Popconfirm
            title="Delete this branding?"
            onConfirm={() => handleDelete(record.branding_id)}
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
      title="Brandings"
      extra={
        <Space>
          <Search
            placeholder="Search brandings..."
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onSearch={() => fetchBrandings(selectedArtist)}
            style={{ width: 250 }}
            allowClear
          />
          <Select
            placeholder="Filter by Artist"
            value={selectedArtist}
            onChange={(value) => {
              setSelectedArtist(value);
              fetchBrandings(value);
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
            onClick={() => navigate('/brandings/create')}
          >
            Add Branding
          </Button>
        </Space>
      }
    >
      <Table
        columns={columns}
        dataSource={brandings}
        loading={loading}
        rowKey="branding_id"
      />
    </Card>
  );
};

export default BrandingsPage;

