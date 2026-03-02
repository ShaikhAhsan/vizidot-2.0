import React, { useEffect, useState } from 'react';
import { Form, Input, Switch, Card, Row, Col, Upload, Image, Button, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { API_BASE_URL } from '../services/api';

const BrandForm = ({ initialValues = {}, onSubmit, loading = false, isEdit = false }) => {
  const [form] = Form.useForm();
  const [logoFile, setLogoFile] = useState(null);
  const [bannerFile, setBannerFile] = useState(null);

  useEffect(() => {
    const safeInitial = initialValues || {};
    form.setFieldsValue({
      name: safeInitial.name,
      slug: safeInitial.slug,
      description: safeInitial.description,
      is_active: safeInitial.is_active ?? true,
    });

    if (isEdit && safeInitial) {
      if (safeInitial.image) {
        setLogoFile({
          uid: 'existing-logo',
          name: 'logo',
          status: 'done',
          url: safeInitial.image,
          thumbUrl: safeInitial.image,
          response: { data: { id: 'existing-logo', url: safeInitial.image, thumbnailUrl: safeInitial.image } }
        });
      }
      if (safeInitial.brand_slider_image) {
        setBannerFile({
          uid: 'existing-banner',
          name: 'banner',
          status: 'done',
          url: safeInitial.brand_slider_image,
          thumbUrl: safeInitial.brand_slider_image,
          response: { data: { id: 'existing-banner', url: safeInitial.brand_slider_image, thumbnailUrl: safeInitial.brand_slider_image } }
        });
      }
    }
  }, [isEdit, initialValues, form]);

  const removeOnServer = async (file) => {
    try {
      if (file?.response?.data?.id && !String(file.response.data.id).startsWith('existing-')) {
        await fetch(`${API_BASE_URL}/api/v1/upload/image/${file.response.data.id}`, {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${localStorage.getItem('token') || 'demo-token-123'}`
          }
        });
      }
    } catch (e) {
      // non-blocking
    }
  };

  const customUpload = async (options) => {
    const { file, onSuccess, onError } = options;
    const formData = new FormData();
    formData.append('image', file);
    try {
      const res = await fetch(`${API_BASE_URL}/api/v1/upload/image?folder=brands`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${localStorage.getItem('token') || 'demo-token-123'}`
        },
        body: formData
      });
      const result = await res.json();
      if (result.success) onSuccess(result);
      else onError(new Error(result.error || 'Upload failed'));
    } catch (err) {
      onError(err);
    }
  };

  const handleLogoChange = ({ file }) => {
    if (file.status === 'uploading') { setLogoFile(file); return; }
    if (file.status === 'error') { message.error('Logo upload failed'); setLogoFile(null); return; }
    if (file.status === 'done' && file.response?.success) {
      const d = file.response.data;
      setLogoFile({ ...file, url: d.url, thumbUrl: d.thumbnailUrl });
      message.success('Logo uploaded');
    }
  };

  const handleBannerChange = ({ file }) => {
    if (file.status === 'uploading') { setBannerFile(file); return; }
    if (file.status === 'error') { message.error('Banner upload failed'); setBannerFile(null); return; }
    if (file.status === 'done' && file.response?.success) {
      const d = file.response.data;
      setBannerFile({ ...file, url: d.url, thumbUrl: d.thumbnailUrl });
      message.success('Banner uploaded');
    }
  };

  const submit = async (values) => {
    const toUrl = (f, fallback) => f ? (f.response?.data?.url || f.url) : (fallback || null);
    const safeInit = (initialValues && typeof initialValues === 'object') ? initialValues : {};
    const payload = {
      ...values,
      image: toUrl(logoFile, safeInit.image),
      brand_slider_image: toUrl(bannerFile, safeInit.brand_slider_image)
    };
    await onSubmit(payload);
  };

  return (
    <Form form={form} layout="vertical" onFinish={submit} initialValues={{ is_active: true }}>
      <Card title="Brand Details" style={{ marginBottom: 16 }}>
        <Row gutter={16}>
          <Col span={12}>
            <Form.Item name="name" label="Brand Name" rules={[{ required: true, message: 'Please enter brand name' }]}>
              <Input placeholder="Enter brand name" />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item name="slug" label="Slug" rules={[{ required: true, message: 'Please enter slug' }]}>
              <Input placeholder="brand-slug" />
            </Form.Item>
          </Col>
          <Col span={24}>
            <Form.Item name="description" label="Description">
              <Input.TextArea rows={3} placeholder="Enter description" />
            </Form.Item>
          </Col>
        </Row>
      </Card>

      <Card title="Logo (recommended 200x200)" style={{ marginBottom: 16 }}>
        <Upload
          listType="picture-card"
          fileList={logoFile ? [logoFile] : []}
          onChange={handleLogoChange}
          onRemove={async () => { await removeOnServer(logoFile); setLogoFile(null); }}
          customRequest={customUpload}
          accept="image/*"
          maxCount={1}
        >
          {!logoFile && (
            <div>
              <PlusOutlined />
              <div style={{ marginTop: 8 }}>Upload Logo</div>
            </div>
          )}
        </Upload>
        {logoFile && (
          <Image src={logoFile.thumbUrl || logoFile.url} alt="logo" width={120} height={120} style={{ objectFit: 'cover' }} preview={false} />
        )}
      </Card>

      <Card title="Banner (recommended 1200x300)" style={{ marginBottom: 16 }}>
        <Upload
          listType="picture-card"
          fileList={bannerFile ? [bannerFile] : []}
          onChange={handleBannerChange}
          onRemove={async () => { await removeOnServer(bannerFile); setBannerFile(null); }}
          customRequest={customUpload}
          accept="image/*"
          maxCount={1}
        >
          {!bannerFile && (
            <div>
              <PlusOutlined />
              <div style={{ marginTop: 8 }}>Upload Banner</div>
            </div>
          )}
        </Upload>
        {bannerFile && (
          <Image src={bannerFile.thumbUrl || bannerFile.url} alt="banner" width={320} height={120} style={{ objectFit: 'cover' }} preview={false} />
        )}
      </Card>

      <Card title="Status">
        <Form.Item name="is_active" label="Active" valuePropName="checked">
          <Switch />
        </Form.Item>
      </Card>

      <Form.Item>
        <Button type="primary" htmlType="submit" loading={loading}>
          {isEdit ? 'Update Brand' : 'Create Brand'}
        </Button>
      </Form.Item>
    </Form>
  );
};

export default BrandForm;


