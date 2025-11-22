import React, { useState, useEffect } from 'react';
import { Table, Button, Space, Card, message, Popconfirm, Upload, Input, Modal, Form, Image, Avatar } from 'antd';
import { ArrowLeftOutlined, UploadOutlined, EditOutlined, DeleteOutlined, PlayCircleOutlined, VideoCameraOutlined, SoundOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { apiService } from '../services/api';
import { useFirebaseAuth } from '../contexts/FirebaseAuthContext';
import ImageUpload from '../components/ImageUpload';

const { Dragger } = Upload;

// Default thumbnail colors (no external requests needed)
const DEFAULT_VIDEO_COLOR = '#3498db';
const DEFAULT_AUDIO_COLOR = '#9b59b6';

const AlbumTracksPage = () => {
  const { id: albumId } = useParams();
  const [album, setAlbum] = useState(null);
  const [tracks, setTracks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [editingTrack, setEditingTrack] = useState(null);
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [editForm] = Form.useForm();
  const navigate = useNavigate();
  const { user } = useFirebaseAuth();

  useEffect(() => {
    fetchAlbum();
  }, [albumId]);

  useEffect(() => {
    if (album) {
      fetchTracks();
    }
  }, [album, albumId]);

  const fetchAlbum = async () => {
    try {
      const response = await apiService.get(`/api/v1/music/albums/${albumId}`);
      setAlbum(response.data);
    } catch (error) {
      message.error('Failed to fetch album');
      navigate('/albums');
    }
  };

  const fetchTracks = async () => {
    if (!album) return;
    
    setLoading(true);
    try {
      const endpoint = album.album_type === 'audio'
        ? `/api/v1/music/albums/${albumId}/audio-tracks`
        : `/api/v1/music/albums/${albumId}/video-tracks`;
      
      const response = await apiService.get(endpoint);
      setTracks(response.data || []);
    } catch (error) {
      message.error('Failed to fetch tracks');
    } finally {
      setLoading(false);
    }
  };

  const handleFileSelect = (info) => {
    const files = info.fileList
      .map(file => file.originFileObj || file)
      .filter(file => file instanceof File);
    setSelectedFiles(files);
  };

  const handleUpload = async () => {
    if (!user) {
      message.error('Please log in to upload files');
      return;
    }

    if (selectedFiles.length === 0) {
      message.error('Please select files to upload');
      return;
    }

    setUploading(true);
    try {
      const token = await user.getIdToken();
      const formData = new FormData();
      
      selectedFiles.forEach((file) => {
        formData.append('files', file);
      });

      const response = await fetch(
        `/api/v1/media/albums/${albumId}/media?type=${album.album_type}`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`
          },
          body: formData
        }
      );

      const result = await response.json();

      if (result.success) {
        message.success(`Successfully uploaded ${result.data.length} track(s)`);
        setSelectedFiles([]);
        fetchTracks();
      } else {
        message.error(result.error || 'Upload failed');
      }
    } catch (error) {
      console.error('Upload error:', error);
      message.error('Failed to upload files');
    } finally {
      setUploading(false);
    }
  };

  const handleEdit = (track) => {
    setEditingTrack(track);
    editForm.setFieldsValue({
      title: track.title,
      thumbnail_url: track.thumbnail_url || ''
    });
    setEditModalVisible(true);
  };

  const handleSaveEdit = async () => {
    try {
      const values = await editForm.validateFields();
      const endpoint = album.album_type === 'audio'
        ? `/api/v1/music/audio-tracks/${editingTrack.audio_id}`
        : `/api/v1/music/video-tracks/${editingTrack.video_id}`;
      
      await apiService.put(endpoint, values);
      message.success('Track updated successfully');
      setEditModalVisible(false);
      setEditingTrack(null);
      fetchTracks();
    } catch (error) {
      message.error('Failed to update track');
    }
  };

  const handleDelete = async (track) => {
    try {
      const endpoint = album.album_type === 'audio'
        ? `/api/v1/music/audio-tracks/${track.audio_id}`
        : `/api/v1/music/video-tracks/${track.video_id}`;
      
      await apiService.delete(endpoint);
      message.success('Track deleted successfully');
      fetchTracks();
    } catch (error) {
      message.error('Failed to delete track');
    }
  };

  const columns = [
    {
      title: '#',
      dataIndex: 'track_number',
      key: 'track_number',
      width: 60,
    },
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
    },
    {
      title: 'Thumbnail',
      key: 'thumbnail',
      width: 120,
      render: (_, record) => {
        const isVideo = album?.album_type === 'video';
        const thumbnailUrl = record.thumbnail_url;
        
        // thumbnail_url now contains the default thumbnail from API if track doesn't have one
        const displayThumbnail = thumbnailUrl;
        
        if (displayThumbnail) {
          return (
            <Image
              src={displayThumbnail}
              alt="Thumbnail"
              width={80}
              height={isVideo ? 60 : 40}
              style={{ objectFit: 'cover', borderRadius: '4px' }}
              preview={{ mask: 'Preview' }}
            />
          );
        }
        
        // Show default thumbnail using Avatar with icon (no external request, no loop)
        return (
          <Avatar
            size={isVideo ? { width: 80, height: 60 } : { width: 80, height: 40 }}
            icon={isVideo ? <VideoCameraOutlined /> : <SoundOutlined />}
            style={{
              backgroundColor: isVideo ? DEFAULT_VIDEO_COLOR : DEFAULT_AUDIO_COLOR,
              borderRadius: '4px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white'
            }}
          />
        );
      },
    },
    {
      title: 'Duration',
      dataIndex: 'duration',
      key: 'duration',
      render: (duration) => {
        if (!duration) return '-';
        const minutes = Math.floor(duration / 60);
        const seconds = duration % 60;
        return `${minutes}:${seconds.toString().padStart(2, '0')}`;
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          >
            Edit
          </Button>
          <Popconfirm
            title="Delete this track?"
            onConfirm={() => handleDelete(record)}
          >
            <Button icon={<DeleteOutlined />} danger>
              Delete
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  if (!album) {
    return <div>Loading...</div>;
  }

  return (
    <Card
      title={`${album.title} - ${album.album_type === 'audio' ? 'Audio' : 'Video'} Tracks`}
      extra={
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/albums')}>
          Back to Albums
        </Button>
      }
    >
      <Space direction="vertical" style={{ width: '100%' }} size="large">
        <Card title="Upload Tracks" type="inner">
          <Dragger
            multiple
            accept={album.album_type === 'audio' ? 'audio/*' : 'video/*'}
            beforeUpload={() => false}
            onChange={handleFileSelect}
            fileList={selectedFiles.map((file, index) => ({
              uid: `-${index}`,
              name: file.name,
              status: 'done',
              originFileObj: file
            }))}
            disabled={uploading}
          >
            <p className="ant-upload-drag-icon">
              <UploadOutlined />
            </p>
            <p className="ant-upload-text">
              Click or drag {album.album_type === 'audio' ? 'audio' : 'video'} files to this area to upload
            </p>
            <p className="ant-upload-hint">
              Support for bulk upload. Files will be named using their filename as the title.
            </p>
          </Dragger>
          <div style={{ marginTop: 16, textAlign: 'right' }}>
            <Button
              type="primary"
              icon={<UploadOutlined />}
              onClick={handleUpload}
              loading={uploading}
              disabled={selectedFiles.length === 0}
            >
              Upload {selectedFiles.length > 0 ? `${selectedFiles.length} ` : ''}File{selectedFiles.length !== 1 ? 's' : ''}
            </Button>
          </div>
        </Card>

        <Table
          columns={columns}
          dataSource={tracks}
          loading={loading}
          rowKey={album.album_type === 'audio' ? 'audio_id' : 'video_id'}
          pagination={false}
        />
      </Space>

      <Modal
        title="Edit Track"
        open={editModalVisible}
        onOk={handleSaveEdit}
        onCancel={() => {
          setEditModalVisible(false);
          setEditingTrack(null);
          editForm.resetFields();
        }}
      >
        <Form form={editForm} layout="vertical">
          <Form.Item
            name="title"
            label="Title"
            rules={[{ required: true, message: 'Please enter track title' }]}
          >
            <Input placeholder="Enter track title" />
          </Form.Item>

          <Form.Item name="thumbnail_url" label="Thumbnail URL" hidden>
            <Input />
          </Form.Item>
          <Form.Item label="Thumbnail">
            <ImageUpload
              folder={album.album_type === 'video' ? 'video-thumbnails' : 'audio-thumbnails'}
              value={editForm.getFieldValue('thumbnail_url')}
              onChange={(url) => {
                // Update form field immediately
                editForm.setFieldsValue({ thumbnail_url: url });
                // Also update the editing track state for immediate preview
                if (editingTrack) {
                  setEditingTrack({ ...editingTrack, thumbnail_url: url });
                }
              }}
            />
            <div style={{ marginTop: 8 }}>
              <Button
                type="link"
                onClick={() => {
                  // Clear thumbnail to use album's default (empty string means no custom thumbnail)
                  editForm.setFieldsValue({ thumbnail_url: '' });
                  // Update editing track state for immediate preview
                  if (editingTrack) {
                    setEditingTrack({ ...editingTrack, thumbnail_url: '' });
                  }
                }}
              >
                Use Default Thumbnail
              </Button>
            </div>
          </Form.Item>
        </Form>
      </Modal>
    </Card>
  );
};

export default AlbumTracksPage;

