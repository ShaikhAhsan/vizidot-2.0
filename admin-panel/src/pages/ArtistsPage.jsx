import React, { useState, useEffect } from 'react';
import { Table, Button, Space, Input, Card, message, Popconfirm, Tag, Image, Avatar } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, UndoOutlined, UserOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';

const { Search } = Input;

const ArtistsPage = () => {
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const navigate = useNavigate();

  const fetchArtists = async (page = 1, search = '') => {
    setLoading(true);
    try {
      const response = await apiService.get(`/api/v1/music/artists?page=${page}&limit=${pagination.pageSize}&search=${search}`);
      setArtists(response.data || []);
      setPagination(prev => ({ ...prev, current: page, total: response.pagination?.total || 0 }));
    } catch (error) {
      message.error('Failed to fetch artists');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchArtists();
  }, []);

  const handleDelete = async (id) => {
    try {
      await apiService.delete(`/api/v1/music/artists/${id}`);
      message.success('Artist deleted successfully');
      fetchArtists(pagination.current, searchText);
    } catch (error) {
      message.error('Failed to delete artist');
    }
  };

  const handleRestore = async (id) => {
    try {
      await apiService.post(`/api/v1/music/artists/${id}/restore`);
      message.success('Artist restored successfully');
      fetchArtists(pagination.current, searchText);
    } catch (error) {
      message.error('Failed to restore artist');
    }
  };

  const columns = [
    {
      title: 'Image',
      dataIndex: 'image_url',
      key: 'image',
      width: 100,
      render: (imageUrl) => {
        if (imageUrl) {
          return (
            <Image
              src={imageUrl}
              alt="Artist"
              width={60}
              height={60}
              style={{
                objectFit: 'cover',
                borderRadius: '8px'
              }}
              preview={{
                mask: 'Preview'
              }}
            />
          );
        }
        return (
          <Avatar
            size={60}
            icon={<UserOutlined />}
            style={{ backgroundColor: '#f0f0f0', color: '#999' }}
          />
        );
      },
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: 'Status',
      key: 'status',
      render: (_, record) => {
        if (record.is_deleted) {
          return <Tag color="red">Deleted</Tag>;
        }
        return record.is_active ? (
          <Tag color="green">Active</Tag>
        ) : (
          <Tag color="orange">Inactive</Tag>
        );
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            onClick={() => navigate(`/artists/edit/${record.artist_id}`)}
            disabled={record.is_deleted}
          >
            Edit
          </Button>
          {record.is_deleted ? (
            <Popconfirm
              title="Restore this artist?"
              onConfirm={() => handleRestore(record.artist_id)}
            >
              <Button icon={<UndoOutlined />} type="default">Restore</Button>
            </Popconfirm>
          ) : (
            <Popconfirm
              title="Delete this artist?"
              onConfirm={() => handleDelete(record.artist_id)}
            >
              <Button icon={<DeleteOutlined />} danger>Delete</Button>
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ];

  return (
    <Card
      title="Artists"
      extra={
        <Space>
          <Search
            placeholder="Search artists..."
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onSearch={() => fetchArtists(1, searchText)}
            onPressEnter={() => fetchArtists(1, searchText)}
            style={{ width: 250 }}
            allowClear
          />
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/artists/create')}
          >
            Add Artist
          </Button>
          <Button onClick={() => navigate('/artists/deleted')}>
            View Deleted
          </Button>
        </Space>
      }
    >
      <Table
        columns={columns}
        dataSource={artists}
        loading={loading}
        rowKey="artist_id"
        pagination={{
          ...pagination,
          onChange: (page) => fetchArtists(page, searchText),
        }}
      />
    </Card>
  );
};

export default ArtistsPage;

