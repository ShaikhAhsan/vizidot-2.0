import React, { useState, useEffect } from 'react';
import { Table, Button, Space, Card, message, Popconfirm, Tag, Select, Image, Avatar } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, PictureOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import { Input } from 'antd';
import { useArtist } from '../contexts/ArtistContext';

const { Search } = Input;
const { Option } = Select;

const BrandingsPage = () => {
  const [brandings, setBrandings] = useState([]);
  const [artists, setArtists] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [selectedArtist, setSelectedArtist] = useState('');
  const navigate = useNavigate();
  const { getArtistQueryParam } = useArtist();

  useEffect(() => {
    fetchArtists();
    fetchBrandings();
  }, [getArtistQueryParam]);

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
      const artistFilter = getArtistQueryParam();
      const queryParams = new URLSearchParams();
      
      // Use artist filter from context if available, otherwise use local filter
      const filterArtistId = artistFilter.artist_id || artistId;
      if (filterArtistId) {
        queryParams.append('artist_id', filterArtistId);
      }
      
      const url = queryParams.toString() 
        ? `/api/v1/music/brandings?${queryParams.toString()}`
        : '/api/v1/music/brandings';
      
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
      title: 'Logo',
      dataIndex: 'logo_url',
      key: 'logo',
      width: 100,
      render: (logoUrl) => {
        if (logoUrl) {
          return (
            <Image
              src={logoUrl}
              alt="Branding Logo"
              width={60}
              height={60}
              style={{ objectFit: 'cover', borderRadius: '8px' }}
              preview={{ mask: 'Preview' }}
            />
          );
        }
        return (
          <Avatar
            size={60}
            icon={<PictureOutlined />}
            style={{ backgroundColor: '#f0f0f0', color: '#999' }}
          />
        );
      },
    },
    {
      title: 'Branding Name',
      dataIndex: 'branding_name',
      key: 'branding_name',
    },
    {
      title: 'Background Color',
      dataIndex: 'background_color',
      key: 'background_color',
      width: 150,
      render: (color) => {
        if (color) {
          return (
            <Space>
              <div
                style={{
                  width: '40px',
                  height: '40px',
                  backgroundColor: color,
                  borderRadius: '4px',
                  border: '1px solid #d9d9d9',
                  display: 'inline-block'
                }}
              />
              <span style={{ fontFamily: 'monospace' }}>{color}</span>
            </Space>
          );
        }
        return <span style={{ color: '#999' }}>No color</span>;
      },
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
      title: 'Tagline',
      dataIndex: 'tagline',
      key: 'tagline',
      render: (tagline) => tagline || '-',
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

