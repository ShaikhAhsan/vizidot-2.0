import React, { useEffect, useState } from 'react';
import { Form, Input, InputNumber, Switch, Card, Row, Col, Upload, Image, Button, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { API_BASE_URL } from '../services/api';

const CategoryForm = ({ initialValues = {}, onSubmit, loading = false, isEdit = false }) => {
  const [form] = Form.useForm();
  const [categoryImage, setCategoryImage] = useState(null);
  const [previewVisible, setPreviewVisible] = useState(false);
  const [previewImage, setPreviewImage] = useState('');

  useEffect(() => {
    if (isEdit && initialValues) {
      form.setFieldsValue({
        name: initialValues.name,
        slug: initialValues.slug,
        description: initialValues.description,
        sort_order: initialValues.sort_order ?? 0,
        is_active: initialValues.is_active ?? true
      });

      if (initialValues.image) {
        const file = {
          uid: 'existing-category-image',
          name: 'category-image',
          status: 'done',
          url: initialValues.image,
          thumbUrl: initialValues.thumbnail || initialValues.image,
          response: {
            data: {
              id: 'existing-category-image',
              original: initialValues.image,
              thumbnail: initialValues.thumbnail || initialValues.image,
              url: initialValues.image,
              thumbnailUrl: initialValues.thumbnail || initialValues.image
            }
          }
        };
        setCategoryImage(file);
      }
    } else {
      form.setFieldsValue({ sort_order: 0, is_active: true });
    }
  }, [isEdit, initialValues, form]);

  const getBase64 = (file) => new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result);
    reader.onerror = (err) => reject(err);
  });

  const handleImagePreview = async (file) => {
    if (!file.url && !file.preview) {
      file.preview = await getBase64(file.originFileObj);
    }
    setPreviewImage(file.url || file.preview);
    setPreviewVisible(true);
  };

  const handleImageRemove = async (file) => {
    try {
      if (file.response?.data?.id) {
        await fetch(`${API_BASE_URL}/api/v1/upload/image/${file.response.data.id}`, {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${localStorage.getItem('token') || 'demo-token-123'}`
          }
        });
      }
    } catch (e) {
      console.warn('Failed to delete uploaded image (non-blocking)', e);
    } finally {
      setCategoryImage(null);
    }
  };

  const customUpload = async (options) => {
    const { file, onSuccess, onError } = options;
    const formData = new FormData();
    formData.append('image', file);
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/upload/image?folder=categories`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${localStorage.getItem('token') || 'demo-token-123'}`
        },
        body: formData
      });
      const result = await response.json();
      if (result.success) {
        onSuccess(result);
      } else {
        onError(new Error(result.error || 'Upload failed'));
      }
    } catch (err) {
      onError(err);
    }
  };

  const handleImageChange = (info) => {
    const { file } = info;
    if (file.status === 'uploading') {
      setCategoryImage(file);
      return;
    }
    if (file.status === 'error') {
      message.error(`${file.name} upload failed.`);
      setCategoryImage(null);
      return;
    }
    if (file.status === 'done' && file.response?.success) {
      const uploaded = file.response.data;
      const updated = {
        ...file,
        url: uploaded.url,
        thumbUrl: uploaded.thumbnailUrl,
        response: file.response
      };
      setCategoryImage(updated);
      message.success(`${file.name} uploaded successfully.`);
    }
  };

  const submit = async (values) => {
    const payload = {
      ...values,
      image: categoryImage ? (categoryImage.response?.data?.url || categoryImage.url || categoryImage.preview) : initialValues.image || null,
      thumbnail: categoryImage ? (categoryImage.response?.data?.thumbnailUrl || categoryImage.thumbUrl || categoryImage.url) : (initialValues.thumbnail || initialValues.image || null)
    };
    await onSubmit(payload);
  };

  return (
    <div>
      <Form form={form} layout="vertical" onFinish={submit}>
        <Card title="Category Details" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="name" label="Category Name" rules={[{ required: true, message: 'Please enter category name' }]}>
                <Input placeholder="Enter category name" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="slug" label="Slug" rules={[{ required: true, message: 'Please enter slug' }]}>
                <Input placeholder="category-slug" />
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="description" label="Description">
                <Input.TextArea rows={3} placeholder="Enter description" />
              </Form.Item>
            </Col>
          </Row>
        </Card>

        <Card title="Category Image" style={{ marginBottom: 16 }}>
          <Upload
            listType="picture-card"
            fileList={categoryImage ? [categoryImage] : []}
            onChange={handleImageChange}
            onRemove={handleImageRemove}
            onPreview={handleImagePreview}
            customRequest={customUpload}
            accept="image/*"
            maxCount={1}
          >
            {!categoryImage && (
              <div>
                <PlusOutlined />
                <div style={{ marginTop: 8 }}>Upload Image</div>
              </div>
            )}
          </Upload>
          <div style={{ marginTop: 8, fontSize: 12, color: '#666' }}>
            Upload a single category image. Preview uses 200x200 like product image.
          </div>

          {categoryImage && (
            <div style={{ marginTop: 12 }}>
              <Image
                src={categoryImage.thumbUrl || categoryImage.url || categoryImage.preview}
                alt={categoryImage.name || 'Category'}
                style={{ width: 200, height: 200, objectFit: 'cover' }}
                preview={false}
              />
            </div>
          )}
        </Card>

        <Card title="Display & Order" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="sort_order" label="Sort Order">
                <InputNumber min={0} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="is_active" label="Active" valuePropName="checked">
                <Switch />
              </Form.Item>
            </Col>
          </Row>
        </Card>

        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading}>
            {isEdit ? 'Update Category' : 'Create Category'}
          </Button>
        </Form.Item>
      </Form>

      <Image.PreviewGroup
        preview={{ visible: previewVisible, onVisibleChange: (vis) => setPreviewVisible(vis) }}
      >
        {previewVisible && (
          <Image src={previewImage} style={{ display: 'none' }} />
        )}
      </Image.PreviewGroup>
    </div>
  );
};

export default CategoryForm;
