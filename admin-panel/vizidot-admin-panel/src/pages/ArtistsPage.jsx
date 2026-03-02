import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Table, Button, Space, Input, Card, message, Popconfirm, Tag, Image, Avatar } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, UndoOutlined, UserOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import { useArtist } from '../contexts/ArtistContext';
import { useFirebaseAuth } from '../contexts/FirebaseAuthContext';

const { Search } = Input;

const ArtistsPage = () => {
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
  const navigate = useNavigate();
  const { getArtistQueryParam } = useArtist();
  const { isSuperAdmin, userProfile } = useFirebaseAuth();
  const superAdmin = isSuperAdmin();
  const assignedArtistIds = useMemo(
    () => new Set((userProfile?.assignedArtists || []).map((artist) => artist.artist_id)),
    [userProfile]
  );

  const fetchArtists = useCallback(async (page = 1, search = '') => {
    setLoading(true);
    try {
      const artistFilter = getArtistQueryParam();
      const queryParams = new URLSearchParams({
        page: page.toString(),
        limit: pagination.pageSize.toString(),
        search: search || ''
      });
      
      // Add artist_id filter if an artist is selected
      if (artistFilter.artist_id) {
        queryParams.append('artist_id', artistFilter.artist_id);
      }
      
      const response = await apiService.get(`/api/v1/music/artists?${queryParams.toString()}`);
      let fetchedArtists = response.data || [];
      if (!superAdmin && assignedArtistIds.size > 0) {
        fetchedArtists = fetchedArtists.filter((artist) => assignedArtistIds.has(artist.artist_id));
      } else if (!superAdmin && assignedArtistIds.size === 0) {
        fetchedArtists = [];
      }
      setArtists(fetchedArtists);
      const totalCount = superAdmin ? (response.pagination?.total || fetchedArtists.length) : fetchedArtists.length;
      setPagination(prev => ({ ...prev, current: page, total: totalCount }));
    } catch (error) {
      message.error('Failed to fetch artists');
    } finally {
      setLoading(false);
    }
  }, [getArtistQueryParam, pagination.pageSize, superAdmin, assignedArtistIds]);

  useEffect(() => {
    fetchArtists();
  }, [fetchArtists]);

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
      title: 'Shop',
      key: 'shop',
      render: (_, record) => {
        if (record.shop) {
          return <Tag color="blue">{record.shop.shop_name}</Tag>;
        }
        return <span style={{ color: '#999' }}>-</span>;
      },
    },
    {
      title: 'Brandings',
      key: 'brandings',
      render: (_, record) => {
        if (record.brandings && record.brandings.length > 0) {
          return (
            <Space size="small" wrap>
              {record.brandings.map((branding) => (
                <Space key={branding.branding_id} size="small">
                  {branding.logo_url ? (
                    <Image
                      src={branding.logo_url}
                      alt={branding.branding_name}
                      width={24}
                      height={24}
                      style={{
                        objectFit: 'cover',
                        borderRadius: '4px'
                      }}
                      preview={{ mask: 'Preview' }}
                    />
                  ) : (
                    <Avatar
                      size={24}
                      style={{
                        backgroundColor: branding.background_color || '#f0f0f0',
                        fontSize: '12px'
                      }}
                    >
                      {branding.branding_name?.charAt(0) || 'B'}
                    </Avatar>
                  )}
                  <span>{branding.branding_name}</span>
                </Space>
              ))}
            </Space>
          );
        }
        return <span style={{ color: '#999' }}>-</span>;
      },
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
          {superAdmin && (
            record.is_deleted ? (
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
            )
          )}
        </Space>
      ),
    },
  ];


  return (
    <Card title="Artists">
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
          placeholder="Search artists..."
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          onSearch={() => fetchArtists(1, searchText)}
          onPressEnter={() => fetchArtists(1, searchText)}
          style={{ flex: '1 1 240px', minWidth: 200 }}
          allowClear
        />
        {superAdmin && (
          <div style={{ marginLeft: 'auto' }}>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={() => navigate('/artists/create')}
            >
              Add Artist
            </Button>
          </div>
        )}
      </div>
      <Table
        columns={columns}
        dataSource={artists}
        loading={loading}
        rowKey="artist_id"
        pagination={{
          ...pagination,
          onChange: (page) => fetchArtists(page, searchText),
        }}
        scroll={{ x: 'max-content' }}
      />
    </Card>
  );
};

export default ArtistsPage;

