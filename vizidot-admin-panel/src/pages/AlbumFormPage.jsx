import React, { useState, useEffect, useCallback } from 'react';
import { Form, Input, Button, Card, message, Select, DatePicker, Switch } from 'antd';
import { SaveOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { apiService } from '../services/api';
import ImageUpload from '../components/ImageUpload';
import dayjs from 'dayjs';

const { Option } = Select;
const { TextArea } = Input;

const AlbumFormPage = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [imageUrl, setImageUrl] = useState('');
  const [defaultThumbnailUrl, setDefaultThumbnailUrl] = useState('');
  const [availableArtists, setAvailableArtists] = useState([]);
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = !!id;

  const fetchArtists = useCallback(async () => {
    try {
      const response = await apiService.get('/api/v1/music/artists?limit=1000');
      setAvailableArtists(response.data || []);
    } catch (error) {
      console.error('Failed to fetch artists');
    }
  }, []);

  const fetchAlbum = useCallback(async () => {
    try {
      const response = await apiService.get(`/api/v1/music/albums/${id}`);
      const album = response.data;
      form.setFieldsValue({
        ...album,
        release_date: album.release_date ? dayjs(album.release_date) : null
      });
      if (album.cover_image_url) {
        setImageUrl(album.cover_image_url);
      }
      if (album.default_track_thumbnail) {
        setDefaultThumbnailUrl(album.default_track_thumbnail);
      }
    } catch (error) {
      message.error('Failed to fetch album');
      navigate('/albums');
    }
  }, [form, id, navigate]);

  useEffect(() => {
    fetchArtists();
  }, [fetchArtists]);

  useEffect(() => {
    if (isEdit) {
      fetchAlbum();
    }
  }, [fetchAlbum, isEdit]);

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const { branding_id, ...albumData } = values;
      const data = {
        ...albumData,
        cover_image_url: imageUrl,
        default_track_thumbnail: defaultThumbnailUrl,
        release_date: values.release_date ? values.release_date.format('YYYY-MM-DD') : null
      };

      if (isEdit) {
        await apiService.put(`/api/v1/music/albums/${id}`, data);
        message.success('Album updated successfully');
      } else {
        await apiService.post('/api/v1/music/albums', data);
        message.success('Album created successfully');
      }
      navigate('/albums');
    } catch (error) {
      message.error(isEdit ? 'Failed to update album' : 'Failed to create album');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card
      title={isEdit ? 'Edit Album' : 'Create Album'}
      extra={
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/albums')}>
          Back
        </Button>
      }
    >
      <Form
        form={form}
        layout="vertical"
        onFinish={onFinish}
        initialValues={{ is_active: true }}
      >
        <Form.Item
          name="artist_id"
          label="Artist"
          rules={[{ required: true, message: 'Please select an artist' }]}
        >
          <Select
            placeholder="Select an artist"
            showSearch
            filterOption={(input, option) =>
              (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
            }
            disabled={isEdit}
          >
            {availableArtists.map(artist => (
              <Option key={artist.artist_id} value={artist.artist_id}>
                {artist.name}
              </Option>
            ))}
          </Select>
        </Form.Item>

        <Form.Item
          name="title"
          label="Album Title"
          rules={[{ required: true, message: 'Please enter album title' }]}
        >
          <Input placeholder="Enter album title" />
        </Form.Item>

        <Form.Item name="description" label="Description">
          <TextArea rows={4} placeholder="Enter album description" />
        </Form.Item>

        <Form.Item
          name="album_type"
          label="Album Type"
          rules={[{ required: true, message: 'Please select album type' }]}
        >
          <Select placeholder="Select album type">
            <Option value="audio">Audio</Option>
            <Option value="video">Video</Option>
          </Select>
        </Form.Item>

        <Form.Item name="release_date" label="Release Date">
          <DatePicker
            style={{ width: '100%' }}
            format="YYYY-MM-DD"
            placeholder="Select release date"
          />
        </Form.Item>

        <Form.Item
          name="is_active"
          label="Status"
          valuePropName="checked"
          initialValue={true}
        >
          <Switch
            checkedChildren="Active"
            unCheckedChildren="Inactive"
          />
        </Form.Item>

        <Form.Item name="cover_image_url" label="Cover Image URL" hidden>
          <Input />
        </Form.Item>

        <Form.Item label="Cover Image">
          <ImageUpload
            folder="albums"
            value={imageUrl}
            onChange={(url) => {
              setImageUrl(url);
              form.setFieldsValue({ cover_image_url: url });
            }}
          />
        </Form.Item>

        <Form.Item name="default_track_thumbnail" label="Default Track Thumbnail URL" hidden>
          <Input />
        </Form.Item>

        <Form.Item label="Default Track Thumbnail">
          <ImageUpload
            folder="album-track-thumbnails"
            value={defaultThumbnailUrl}
            onChange={(url) => {
              setDefaultThumbnailUrl(url);
              form.setFieldsValue({ default_track_thumbnail: url });
            }}
          />
          <div style={{ marginTop: 8, fontSize: '12px', color: '#999' }}>
            This thumbnail will be used as default for all tracks in this album that don't have a custom thumbnail.
          </div>
        </Form.Item>

        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} icon={<SaveOutlined />}>
            {isEdit ? 'Update Album' : 'Create Album'}
          </Button>
        </Form.Item>
      </Form>
    </Card>
  );
};

export default AlbumFormPage;

