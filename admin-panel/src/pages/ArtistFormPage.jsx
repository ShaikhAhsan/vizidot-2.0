import React, { useState, useEffect } from 'react';
import { Form, Input, Button, Card, message, Switch } from 'antd';
import { SaveOutlined, ArrowLeftOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { apiService } from '../services/api';
import ImageUpload from '../components/ImageUpload';

const ArtistFormPage = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [imageUrl, setImageUrl] = useState('');
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = !!id;
  const { user } = useFirebaseAuth();

  useEffect(() => {
    if (isEdit) {
      fetchArtist();
    }
  }, [id]);

  const fetchArtist = async () => {
    try {
      const response = await apiService.get(`/api/v1/music/artists/${id}`);
      const artist = response.data;
      form.setFieldsValue(artist);
      if (artist.image_url) {
        setImageUrl(artist.image_url);
      }
    } catch (error) {
      message.error('Failed to fetch artist');
      navigate('/artists');
    }
  };

  const handleImageUpload = async (file) => {
    setUploading(true);
    try {
      if (!user) {
        message.error('Please log in to upload images');
        setUploading(false);
        return false;
      }
      
      const formData = new FormData();
      formData.append('image', file);
      
      // Get auth token from the authenticated user
      const token = await user.getIdToken();
      
      // Upload with folder parameter for artists
      const response = await fetch('/api/v1/upload/image?folder=artists', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          // Don't set Content-Type for FormData, browser will set it with boundary
        },
        body: formData,
      });

      const data = await response.json();

      if (response.ok && data.success) {
        const uploadedUrl = data.data.url;
        form.setFieldsValue({ image_url: uploadedUrl });
        setImageUrl(uploadedUrl);
        message.success('Image uploaded successfully');
        setUploading(false);
        return false; // Prevent default upload
      } else {
        const errorMsg = data.error || 'Image upload failed';
        console.error('Upload error:', errorMsg, data);
        message.error(errorMsg);
        setUploading(false);
        return false;
      }
    } catch (error) {
      console.error('Upload exception:', error);
      message.error(`Image upload failed: ${error.message}`);
      setUploading(false);
      return false;
    }
  };

  const onFinish = async (values) => {
    setLoading(true);
    try {
      if (isEdit) {
        await apiService.put(`/api/v1/music/artists/${id}`, values);
        message.success('Artist updated successfully');
      } else {
        await apiService.post('/api/v1/music/artists', values);
        message.success('Artist created successfully');
      }
      navigate('/artists');
    } catch (error) {
      message.error(isEdit ? 'Failed to update artist' : 'Failed to create artist');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card
      title={isEdit ? 'Edit Artist' : 'Create Artist'}
      extra={
        <Button icon={<ArrowLeftOutlined />} onClick={() => navigate('/artists')}>
          Back
        </Button>
      }
    >
      <Form
        form={form}
        layout="vertical"
        onFinish={onFinish}
      >
        <Form.Item
          name="name"
          label="Artist Name"
          rules={[{ required: true, message: 'Please enter artist name' }]}
        >
          <Input placeholder="Enter artist name" />
        </Form.Item>

        <Form.Item name="bio" label="Biography">
          <Input.TextArea rows={4} placeholder="Enter biography" />
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

        <Form.Item name="image_url" label="Artist Image" hidden>
          <Input />
        </Form.Item>

        <Form.Item label="Artist Image">
          {imageUrl ? (
            <div style={{ marginBottom: 16 }}>
              <Image
                src={imageUrl}
                alt="Artist"
                style={{
                  maxWidth: '300px',
                  maxHeight: '300px',
                  objectFit: 'cover',
                  borderRadius: '8px',
                  marginBottom: '12px'
                }}
                preview={{
                  mask: 'Preview'
                }}
              />
              <div>
                <Button
                  icon={<DeleteOutlined />}
                  danger
                  onClick={() => {
                    setImageUrl('');
                    form.setFieldsValue({ image_url: '' });
                  }}
                  style={{ marginRight: 8 }}
                >
                  Remove Image
                </Button>
                <Button
                  icon={<UploadOutlined />}
                  onClick={() => document.getElementById('image-upload-input')?.click()}
                  loading={uploading}
                >
                  Change Image
                </Button>
              </div>
            </div>
          ) : (
            <Upload
              beforeUpload={handleImageUpload}
              showUploadList={false}
              accept="image/*"
            >
              <Button icon={<UploadOutlined />} loading={uploading}>
                Upload Image
              </Button>
            </Upload>
          )}
          <input
            id="image-upload-input"
            type="file"
            accept="image/*"
            style={{ display: 'none' }}
            onChange={(e) => {
              if (e.target.files && e.target.files[0]) {
                handleImageUpload(e.target.files[0]);
              }
            }}
          />
        </Form.Item>

        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} icon={<SaveOutlined />}>
            {isEdit ? 'Update Artist' : 'Create Artist'}
          </Button>
        </Form.Item>
      </Form>
    </Card>
  );
};

export default ArtistFormPage;

