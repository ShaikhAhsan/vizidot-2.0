import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Table, Button, Space, Input, Card, message, Popconfirm, Tag, Select, Image, Avatar } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined, UserOutlined, SoundOutlined, FileAddOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import { useArtist } from '../contexts/ArtistContext';
import { useFirebaseAuth } from '../contexts/FirebaseAuthContext';

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
  const { getArtistQueryParam } = useArtist();
  const { isSuperAdmin, userProfile } = useFirebaseAuth();
  const superAdmin = isSuperAdmin();
  const assignedArtistIds = useMemo(
    () => new Set((userProfile?.assignedArtists || []).map((artist) => artist.artist_id)),
    [userProfile]
  );

  const fetchArtists = useCallback(async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      const fetchedArtists = response.data || [];
      if (superAdmin || assignedArtistIds.size === 0) {
        setArtists(fetchedArtists);
      } else {
        setArtists(fetchedArtists.filter((artist) => assignedArtistIds.has(artist.artist_id)));
      }
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  }, [superAdmin, assignedArtistIds]);

  const fetchAlbums = useCallback(async (page = 1, search = '', artistId = '', type = '') => {
    setLoading(true);
    try {
      const artistFilter = getArtistQueryParam();
      const queryParams = new URLSearchParams({
        page: page.toString(),
        limit: pagination.pageSize.toString()
      });
      
      if (search) queryParams.append('search', search);
      if (artistId) queryParams.append('artist_id', artistId);
      if (type) queryParams.append('album_type', type);
      
      // Add artist_id filter from context if an artist is selected
      if (artistFilter.artist_id) {
        queryParams.append('artist_id', artistFilter.artist_id);
      }
      
      const response = await apiService.get(`/api/v1/music/albums?${queryParams.toString()}`);
      // Handle both response.data (if it's an array) or response.data.data (if nested)
      let albumsData = Array.isArray(response.data) ? response.data : (response.data?.data || []);
      if (!superAdmin) {
        albumsData = albumsData.filter((album) => {
          const albumArtistId = album.artist_id || album.artist?.artist_id;
          return albumArtistId ? assignedArtistIds.has(albumArtistId) : false;
        });
      }
      setAlbums(albumsData);
      const totalCount = superAdmin ? (response.data?.pagination?.total || response.pagination?.total || albumsData.length) : albumsData.length;
      setPagination(prev => ({ ...prev, current: page, total: totalCount }));
    } catch (error) {
      message.error('Failed to fetch albums');
    } finally {
      setLoading(false);
    }
  }, [getArtistQueryParam, pagination.pageSize, superAdmin, assignedArtistIds]);

  useEffect(() => {
    fetchArtists();
    fetchAlbums();
  }, [fetchArtists, fetchAlbums]);

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
            icon={<FileAddOutlined />}
            onClick={() => navigate(`/albums/${record.album_id}/tracks`)}
            type="primary"
          >
            Manage Tracks
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
    <Card title="Albums">
      <div
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          gap: 12,
          marginBottom: 16,
          alignItems: 'center'
        }}
      >
        <Input
          placeholder="Search albums..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          onPressEnter={() => fetchAlbums(1, searchText, selectedArtist, albumType)}
          style={{ flex: '1 1 240px', minWidth: 200 }}
        />
        <Select
          placeholder="Filter by Artist"
          value={selectedArtist}
          onChange={(value) => {
            setSelectedArtist(value);
            fetchAlbums(1, searchText, value, albumType);
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
        <Select
          placeholder="Filter by Type"
          value={albumType}
          onChange={(value) => {
            setAlbumType(value);
            fetchAlbums(1, searchText, selectedArtist, value);
          }}
          allowClear
          style={{ flex: '0 1 150px', minWidth: 140 }}
        >
          <Option value="audio">Audio</Option>
          <Option value="video">Video</Option>
        </Select>
        <div style={{ marginLeft: 'auto' }}>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/albums/create')}
          >
            Add Album
          </Button>
        </div>
      </div>

      <Table
        columns={columns}
        dataSource={albums}
        loading={loading}
        rowKey="album_id"
        pagination={{
          ...pagination,
          onChange: (page) => fetchAlbums(page, searchText, selectedArtist, albumType),
        }}
        scroll={{ x: 'max-content' }}
      />
    </Card>
  );
};

export default AlbumsPage;

