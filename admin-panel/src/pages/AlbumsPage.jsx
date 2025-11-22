import React, { useState, useEffect } from 'react';
import { Table, Button, Space, Input, Card, message, Popconfirm, Tag, Select, Image, Avatar } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined, SearchOutlined, UserOutlined, SoundOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';

const { Option } = Select;

const AlbumsPage = () => {
  const [albums, setAlbums] = useState([]);
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [selectedArtist, setSelectedArtist] = useState('');
  const [albumType, setAlbumType] = useState('');
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const navigate = useNavigate();

  useEffect(() => {
    fetchArtists();
    fetchAlbums();
  }, []);

  const fetchArtists = async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  };

  const fetchAlbums = async (page = 1, search = '', artistId = '', type = '') => {
    setLoading(true);
    try {
      let url = `/api/v1/music/albums?page=${page}&limit=${pagination.pageSize}`;
      if (search) url += `&search=${search}`;
      if (artistId) url += `&artist_id=${artistId}`;
      if (type) url += `&album_type=${type}`;
      
      const response = await apiService.get(url);
      // Handle both response.data (if it's an array) or response.data.data (if nested)
      const albumsData = Array.isArray(response.data) ? response.data : (response.data?.data || []);
      setAlbums(albumsData);
      setPagination(prev => ({ ...prev, current: page, total: response.data?.pagination?.total || response.pagination?.total || 0 }));
    } catch (error) {
      message.error('Failed to fetch albums');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    try {
      await apiService.delete(`/api/v1/music/albums/${id}`);
      message.success('Album deleted successfully');
      fetchAlbums(pagination.current, searchText, selectedArtist, albumType);
    } catch (error) {
      message.error('Failed to delete album');
    }
  };

  const columns = [
    {
      title: 'Album Image',
      dataIndex: 'cover_image_url',
      key: 'album_image',
      width: 100,
      render: (imageUrl) => {
        if (imageUrl) {
          return (
            <Image
              src={imageUrl}
              alt="Album"
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
            icon={<SoundOutlined />}
            style={{ backgroundColor: '#f0f0f0', color: '#999' }}
          />
        );
      },
    },
    {
      title: 'Artist Image',
      key: 'artist_image',
      width: 100,
      render: (_, record) => {
        const artistImageUrl = record.artist?.image_url;
        if (artistImageUrl) {
          return (
            <Image
              src={artistImageUrl}
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
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
    },
    {
      title: 'Artist',
      key: 'artist',
      render: (_, record) => record.artist?.name || '-',
    },
    {
      title: 'Type',
      dataIndex: 'album_type',
      key: 'album_type',
      render: (type) => (
        <Tag color={type === 'audio' ? 'blue' : 'purple'}>
          {type?.toUpperCase()}
        </Tag>
      ),
    },
    {
      title: 'Release Date',
      dataIndex: 'release_date',
      key: 'release_date',
      render: (date) => date ? new Date(date).toLocaleDateString() : '-',
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
            icon={<EyeOutlined />}
            onClick={() => navigate(`/albums/${record.album_id}`)}
          >
            View
          </Button>
          <Button
            icon={<EditOutlined />}
            onClick={() => navigate(`/albums/edit/${record.album_id}`)}
          >
            Edit
          </Button>
          <Popconfirm
            title="Delete this album?"
            onConfirm={() => handleDelete(record.album_id)}
          >
            <Button icon={<DeleteOutlined />} danger>Delete</Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <Card
      title="Albums"
      extra={
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => navigate('/albums/create')}
        >
          Add Album
        </Button>
      }
    >
      <Space style={{ marginBottom: 16, width: '100%' }} direction="vertical" size="middle">
        <Space>
          <Input
            placeholder="Search albums..."
            prefix={<SearchOutlined />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onPressEnter={() => fetchAlbums(1, searchText, selectedArtist, albumType)}
            style={{ width: 250 }}
          />
          <Select
            placeholder="Filter by Artist"
            value={selectedArtist}
            onChange={(value) => {
              setSelectedArtist(value);
              fetchAlbums(1, searchText, value, albumType);
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
          <Select
            placeholder="Filter by Type"
            value={albumType}
            onChange={(value) => {
              setAlbumType(value);
              fetchAlbums(1, searchText, selectedArtist, value);
            }}
            allowClear
            style={{ width: 150 }}
          >
            <Option value="audio">Audio</Option>
            <Option value="video">Video</Option>
          </Select>
        </Space>
      </Space>
      
      <Table
        columns={columns}
        dataSource={albums}
        loading={loading}
        rowKey="album_id"
        pagination={{
          ...pagination,
          onChange: (page) => fetchAlbums(page, searchText, selectedArtist, albumType),
        }}
      />
    </Card>
  );
};

export default AlbumsPage;

