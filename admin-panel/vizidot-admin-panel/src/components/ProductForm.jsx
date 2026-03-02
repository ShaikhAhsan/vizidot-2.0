import React, { useState, useEffect } from 'react';
import {
  Form,
  Input,
  InputNumber,
  Select,
  Switch,
  DatePicker,
  Button,
  Row,
  Col,
  Card,
  message,
  Tag as AntTag,
  Space,
  Modal,
  ColorPicker,
  Upload,
  Image,
  AutoComplete
} from 'antd';
import {
  PlusOutlined
} from '@ant-design/icons';
import { mockData } from '../services/mockData';
import { API_BASE_URL } from '../services/api';
import dayjs from 'dayjs';

const { TextArea } = Input;
const { Option } = Select;

const ProductForm = ({ 
  initialValues = {}, 
  onSubmit, 
  loading = false,
  isEdit = false 
}) => {
  const [form] = Form.useForm();
  const [brands, setBrands] = useState([]);
  const [categories, setCategories] = useState([]);
  const [availableTags, setAvailableTags] = useState([]);
  const [selectedTags, setSelectedTags] = useState([]);
  const [tagSearchValue, setTagSearchValue] = useState('');
  const [isTagModalVisible, setIsTagModalVisible] = useState(false);
  const [newTagForm] = Form.useForm();
  const [productImage, setProductImage] = useState(null);
  const [previewVisible, setPreviewVisible] = useState(false);
  const [previewImage, setPreviewImage] = useState('');
  const [units, setUnits] = useState([]);
  const [unitSearchValue, setUnitSearchValue] = useState('');

  // Compute robust initial values for the form (create vs edit)
  const defaultCreateValues = {
    is_active: true,
    is_featured: false,
    is_digital: true,
    requires_prescription: false,
    min_stock_alert: 5,
    unit: 'piece'
  };

  const mergedInitialValues = isEdit
    ? {
        ...initialValues,
        is_active: initialValues?.is_active !== undefined ? !!initialValues.is_active : true,
        is_digital: initialValues?.is_digital !== undefined ? !!initialValues.is_digital : true,
        is_featured: initialValues?.is_featured !== undefined ? !!initialValues.is_featured : false,
        requires_prescription: initialValues?.requires_prescription !== undefined ? !!initialValues.requires_prescription : false,
      }
    : { ...defaultCreateValues, ...(initialValues || {}) };

  // Always push merged initial values into the form state so switches reflect correctly
  useEffect(() => {
    try {
      form.setFieldsValue(mergedInitialValues);
    } catch (e) {
      // non-blocking
    }
  }, [form, mergedInitialValues]);

  // Load brands and categories on component mount
  useEffect(() => {
    loadBrands();
    loadTags();
    loadUnits();
    
    // Load categories with retry mechanism for business context
    const loadCategoriesWithRetry = () => {
      const businessContextHeaders = window.getBusinessContextHeaders?.() || {};
      if (businessContextHeaders['x-business-id']) {
        console.log('Business context available, loading categories...');
        loadCategories();
      } else {
        console.log('Business context not available, retrying in 1 second...');
        setTimeout(loadCategoriesWithRetry, 1000);
      }
    };
    
    loadCategoriesWithRetry();
  }, []);

  // Reload categories when business context changes
  useEffect(() => {
    // Wait a bit for business context to be available
    const timer = setTimeout(() => {
      loadCategories();
    }, 1000);
    return () => clearTimeout(timer);
  }, []);

  // Also reload categories when the component receives new props (like when business changes)
  useEffect(() => {
    if (isEdit && initialValues) {
      // Reload categories when editing a product to ensure we have the right business context
      const timer = setTimeout(() => {
        loadCategories();
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [isEdit, initialValues]);

  // Remove extra create-mode coercion; mergedInitialValues handles defaults

  // Initialize tags when available tags are loaded
  useEffect(() => {
    if (availableTags.length > 0 && isEdit && initialValues && initialValues.tags) {
      // Set selected tags from initial values
      const initialTags = initialValues.tags.map(tag => ({
        id: tag.id,
        name: tag.name,
        color: tag.color || '#007bff'
      }));
      setSelectedTags(initialTags);
    }
  }, [availableTags, isEdit, initialValues]);

  // Set initial values when editing
  useEffect(() => {
    if (isEdit && initialValues) {
      form.setFieldsValue({
        ...initialValues,
        expiry_date: initialValues.expiry_date ? dayjs(initialValues.expiry_date) : null,
        // Handle multiple categories
        category_ids: initialValues.categories ? initialValues.categories.map(cat => cat.id) : [],
        // Ensure switches reflect saved value (coerce to boolean) and sensible fallbacks
        is_active: initialValues.is_active !== undefined ? !!initialValues.is_active : true,
        is_digital: initialValues.is_digital !== undefined ? !!initialValues.is_digital : true,
        is_featured: initialValues.is_featured !== undefined ? !!initialValues.is_featured : false,
        requires_prescription: initialValues.requires_prescription !== undefined ? !!initialValues.requires_prescription : false,
      });
      
      // Set selected tags
      if (initialValues.tags && Array.isArray(initialValues.tags)) {
        setSelectedTags(initialValues.tags.map(tag => ({
          id: tag.id,
          name: tag.name,
          color: tag.color
        })));
      }

      // Set existing image
      if (initialValues.image) {
        const imageFile = {
          uid: 'existing-image',
          name: 'product-image',
          status: 'done',
          url: initialValues.image,
          thumbUrl: initialValues.thumbnail || initialValues.image,
          response: {
            data: {
              id: 'existing-image',
              original: initialValues.image,
              thumbnail: initialValues.thumbnail || initialValues.image,
              url: initialValues.image,
              thumbnailUrl: initialValues.thumbnail || initialValues.image
            }
          }
        };
        setProductImage(imageFile);
      }
    }
  }, [initialValues, isEdit, form]);

  const loadBrands = async () => {
    try {
      const { adminAPI } = require('../services/api');
      const response = await adminAPI.getBrands();
      if (response.success) {
        setBrands(response.data);
      }
    } catch (error) {
      console.error('Error loading brands:', error);
      setBrands(mockData.brands);
    }
  };

  const loadCategories = async () => {
    try {
      const { adminAPI } = require('../services/api');
      const response = await adminAPI.getCategories();
      if (response.success && Array.isArray(response.data)) {
        setCategories(response.data);
      } else {
        const businessId = (window.getBusinessContextHeaders?.() || {})['x-business-id'];
        const businessCategories = mockData.businessCategories[businessId] || [];
        setCategories(businessCategories);
      }
    } catch (error) {
      console.error('Error loading categories:', error);
      const businessId = (window.getBusinessContextHeaders?.() || {})['x-business-id'];
      const businessCategories = mockData.businessCategories[businessId] || [];
      setCategories(businessCategories);
    }
  };

  const loadTags = async (search = '') => {
    try {
      const { adminAPI } = require('../services/api');
      const res = search
        ? await adminAPI.searchTags(search, 20)
        : await adminAPI.getTags(1, 100);
      if (res.success) {
        setAvailableTags(res.data || []);
        return;
      }
      // Fallback to mock if API returns unexpected shape
      setAvailableTags(mockData.tags);
    } catch (error) {
      console.error('Error loading tags:', error);
      setAvailableTags(mockData.tags);
    }
  };

  const loadUnits = async (search = '') => {
    try {
      const { apiService } = require('../services/api');
      const response = await apiService.get(`/api/v1/units?search=${encodeURIComponent(search)}&limit=20`);
      if (response.success) {
        setUnits(response.data);
      }
    } catch (error) {
      console.error('Error loading units:', error);
      setUnits([
        { name: 'piece', display_name: 'Piece', category: 'count' },
        { name: 'kg', display_name: 'Kilogram', category: 'weight' },
        { name: 'g', display_name: 'Gram', category: 'weight' },
        { name: 'liter', display_name: 'Liter', category: 'volume' },
        { name: 'ml', display_name: 'Milliliter', category: 'volume' },
        { name: 'box', display_name: 'Box', category: 'count' },
        { name: 'pack', display_name: 'Pack', category: 'count' }
      ]);
    }
  };

  const handleTagSearch = (value) => {
    setTagSearchValue(value);
    loadTags(value);
  };

  const handleTagSelect = (value) => {
    const tag = availableTags.find(t => t.name === value);
    if (tag && !selectedTags.find(t => t.id === tag.id)) {
      setSelectedTags([...selectedTags, tag]);
    }
    setTagSearchValue('');
  };

  const handleTagRemove = (tagId) => {
    setSelectedTags(selectedTags.filter(tag => tag.id !== tagId));
  };

  const handleUnitSearch = (value) => {
    setUnitSearchValue(value);
    loadUnits(value);
  };

  const handleUnitSelect = async (value) => {
    try {
      // Check if unit exists in our list
      let unit = units.find(u => u.name === value);
      
      if (!unit) {
        // Create new unit if it doesn't exist
        const { apiService } = require('../services/api');
        const response = await apiService.post('/api/v1/units', {
          name: value,
          display_name: value,
          category: 'other'
        });
        
        if (response.success) {
          unit = response.data;
          setUnits([unit, ...units]);
        }
      } else {
        // Increment usage count for existing unit
        try {
          const { apiService } = require('../services/api');
          await apiService.post(`/api/v1/units/${unit.id}/increment-usage`, {});
        } catch (error) {
          console.warn('Failed to increment unit usage:', error);
        }
      }
      
      // Set the form value
      form.setFieldValue('unit', value);
    } catch (error) {
      console.error('Error handling unit selection:', error);
      message.error('Failed to save unit');
    }
  };

  const handleCreateTag = async () => {
    try {
      const values = await newTagForm.validateFields();
      const { adminAPI } = require('../services/api');
      const resp = await adminAPI.createTagIfNotExists({
        name: values.name,
        description: values.description,
        color: values.color || '#007bff'
      });
      if (!resp.success) {
        throw new Error(resp.error || 'Failed to create tag');
      }
      const newTag = resp.data;
      setSelectedTags([...selectedTags, {
        id: newTag.id,
        name: newTag.name,
        color: newTag.color || '#007bff'
      }]);
      setAvailableTags([newTag, ...availableTags]);
      setIsTagModalVisible(false);
      newTagForm.resetFields();
      message.success('Tag created successfully!');
    } catch (error) {
      console.error('Error creating tag:', error);
      message.error('Error creating tag: ' + (error.response?.data?.error || error.message));
    }
  };

  // Image handling functions
  const handleImageUpload = async (info) => {
    const { file } = info;
    
    // If file is being uploaded
    if (file.status === 'uploading') {
      setProductImage(file);
      return;
    }
    
    // If upload failed
    if (file.status === 'error') {
      message.error(`${file.name} upload failed.`);
      setProductImage(null);
      return;
    }
    
    // If upload succeeded
    if (file.status === 'done' && file.response?.success) {
      const uploadedImage = file.response.data;
      const updatedFile = {
        ...file,
        url: uploadedImage.url,
        thumbUrl: uploadedImage.thumbnailUrl,
        response: file.response
      };
      setProductImage(updatedFile);
      message.success(`${file.name} uploaded successfully.`);
    }
  };

  const handleImageRemove = async (file) => {
    try {
      // If file was uploaded, delete it from server
      if (file.response?.data?.id) {
        const response = await fetch(`${API_BASE_URL}/api/v1/upload/image/${file.response.data.id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token') || 'demo-token-123'}`
          }
        });
        
        if (!response.ok) {
          console.error('Failed to delete image from server');
        }
      }
      
      setProductImage(null);
    } catch (error) {
      console.error('Error removing image:', error);
      message.error('Failed to remove image');
    }
  };

  const handleImagePreview = async (file) => {
    if (!file.url && !file.preview) {
      file.preview = await getBase64(file.originFileObj);
    }
    setPreviewImage(file.url || file.preview);
    setPreviewVisible(true);
  };

  const getBase64 = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result);
      reader.onerror = error => reject(error);
    });
  };

  // Custom upload function
  const customUpload = async (options) => {
    const { file, onSuccess, onError } = options;
    
    const formData = new FormData();
    formData.append('image', file);
    
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/upload/image`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token') || 'demo-token-123'}`
        },
        body: formData
      });
      
      const result = await response.json();
      
      if (result.success) {
        onSuccess(result);
      } else {
        onError(new Error(result.error || 'Upload failed'));
      }
    } catch (error) {
      onError(error);
    }
  };

  const handleSubmit = async (values) => {
    try {
      // Validate categories before submission
      if (values.category_ids && values.category_ids.length > 0) {
        const validCategoryIds = categories.map(cat => cat.id);
        const invalidCategoryIds = values.category_ids.filter(id => !validCategoryIds.includes(id));
        
        if (invalidCategoryIds.length > 0) {
          message.error(`Invalid categories selected: ${invalidCategoryIds.join(', ')}. Please refresh the page and try again.`);
          return;
        }
      }
      
      // Prepare form data
      const formData = {
        ...values,
        expiry_date: values.expiry_date ? values.expiry_date.format('YYYY-MM-DD') : null,
        tag_ids: selectedTags.map(tag => tag.id),
        // Handle multiple categories - if category_ids is provided, use it; otherwise fall back to category_id
        category_id: values.category_ids && values.category_ids.length > 0 ? values.category_ids[0] : values.category_id,
        category_ids: values.category_ids || [],
        // Include single image
        image: productImage ? (productImage.response?.data?.url || productImage.url || productImage.preview) : null,
        thumbnail: productImage ? (productImage.response?.data?.thumbnailUrl || productImage.thumbUrl) : null,
      };

      await onSubmit(formData);
    } catch (error) {
      console.error('Form submission error:', error);
    }
  };

  const formFields = [
    {
      name: 'name',
      label: 'Product Name',
      rules: [{ required: true, message: 'Please enter product name' }],
      component: <Input placeholder="Enter product name" />,
      span: 12
    },
    {
      name: 'sku',
      label: 'SKU',
      component: <Input placeholder="Enter SKU (optional)" />,
      span: 12
    },
    {
      name: 'slug',
      label: 'Slug',
      component: <Input placeholder="product-slug" />,
      span: 12
    },
    {
      name: 'brand_id',
      label: 'Brand',
      component: (
        <Select placeholder="Select brand" allowClear>
          {brands.map(brand => (
            <Option key={brand.id} value={brand.id}>
              {brand.name}
            </Option>
          ))}
        </Select>
      ),
      span: 12
    },
    {
      name: 'category_ids',
      label: 'Categories',
      component: (
        <Select 
          mode="multiple" 
          placeholder="Select categories" 
          allowClear
          showSearch
          filterOption={(input, option) =>
            option.children.toLowerCase().indexOf(input.toLowerCase()) >= 0
          }
        >
          {categories.map(category => (
            <Option key={category.id} value={category.id}>
              {category.name}
            </Option>
          ))}
        </Select>
      ),
      span: 12
    },
    {
      name: 'price',
      label: 'Price',
      rules: [{ required: true, message: 'Please enter price' }],
      component: <InputNumber min={0} step={0.01} placeholder="0.00" style={{ width: '100%' }} />,
      span: 8
    },
    {
      name: 'old_price',
      label: 'Old Price',
      component: <InputNumber min={0} step={0.01} placeholder="0.00" style={{ width: '100%' }} />,
      span: 8
    },
    {
      name: 'cost_price',
      label: 'Cost Price',
      component: <InputNumber min={0} step={0.01} placeholder="0.00" style={{ width: '100%' }} />,
      span: 8
    },
    {
      name: 'stock_quantity',
      label: 'Stock Quantity',
      rules: [{ required: true, message: 'Please enter stock quantity' }],
      component: <InputNumber min={0} placeholder="0" style={{ width: '100%' }} />,
      span: 8
    },
    {
      name: 'min_stock_alert',
      label: 'Min Stock Alert',
      component: <InputNumber min={0} placeholder="5" style={{ width: '100%' }} />,
      span: 8
    },
    {
      name: 'max_quantity_per_order',
      label: 'Max Quantity Per Order',
      component: <InputNumber min={1} placeholder="10" style={{ width: '100%' }} />,
      span: 8
    },
    {
      name: 'unit',
      label: 'Unit',
      component: (
        <AutoComplete
          placeholder="Type or select unit"
          defaultValue="piece"
          value={unitSearchValue}
          onSearch={handleUnitSearch}
          onSelect={handleUnitSelect}
          onChange={(value) => {
            setUnitSearchValue(value);
            form.setFieldValue('unit', value);
          }}
          options={units.map(unit => ({
            value: unit.name,
            label: (
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>{unit.display_name || unit.name}</span>
                <span style={{ color: '#999', fontSize: '12px' }}>
                  {unit.category}
                </span>
              </div>
            )
          }))}
          filterOption={(inputValue, option) =>
            option.value.toLowerCase().includes(inputValue.toLowerCase())
          }
          style={{ width: '100%' }}
        />
      ),
      span: 8
    },
    {
      name: 'expiry_date',
      label: 'Expiry Date',
      component: <DatePicker style={{ width: '100%' }} />,
      span: 8
    },
    {
      name: 'description',
      label: 'Description',
      component: <TextArea rows={4} placeholder="Enter product description" />,
      span: 24
    },
    {
      name: 'short_description',
      label: 'Short Description',
      component: <TextArea rows={2} placeholder="Enter short description" />,
      span: 24
    }
  ];

  return (
    <div>
      <Form
        form={form}
        layout="vertical"
        onFinish={handleSubmit}
        initialValues={mergedInitialValues}
      >
        {/* Basic Information */}
        <Card title="Basic Information" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            {formFields.slice(0, 6).map((field, index) => (
              <Col span={field.span} key={index}>
                <Form.Item
                  name={field.name}
                  label={field.label}
                  rules={field.rules}
                >
                  {field.component}
                </Form.Item>
              </Col>
            ))}
          </Row>
        </Card>

        {/* Product Image */}
        <Card title="Product Image" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 16 }}>
            <Upload
              listType="picture-card"
              fileList={productImage ? [productImage] : []}
              onChange={handleImageUpload}
              onRemove={handleImageRemove}
              onPreview={handleImagePreview}
              customRequest={customUpload}
              accept="image/*"
              maxCount={1}
            >
              {!productImage && (
                <div>
                  <PlusOutlined />
                  <div style={{ marginTop: 8 }}>Upload Image</div>
                </div>
              )}
            </Upload>
            <div style={{ marginTop: 8, fontSize: '12px', color: '#666' }}>
              Upload a single product image. This will be used as the main product image and thumbnail.
            </div>
          </div>
          
          {/* Image preview */}
          {productImage && (
            <div>
              <div style={{ marginBottom: 8, fontWeight: 'bold' }}>Product Image:</div>
              <div style={{ 
                border: '1px solid #d9d9d9', 
                borderRadius: '6px', 
                padding: '8px',
                display: 'inline-block',
                position: 'relative'
              }}>
                <Image
                  src={productImage.thumbUrl || productImage.url || productImage.preview}
                  alt={productImage.name || 'Product Image'}
                  style={{ width: '200px', height: '200px', objectFit: 'cover' }}
                  preview={false}
                  onError={(e) => {
                    // Fallback to original image if thumbnail fails
                    try {
                      if (productImage.url && productImage.url !== productImage.thumbUrl && e.target) {
                        e.target.src = productImage.url;
                      }
                    } catch (error) {
                      console.warn('Error handling image load failure:', error);
                    }
                  }}
                />
                <div style={{
                  position: 'absolute',
                  bottom: 8,
                  left: 8,
                  background: '#52c41a',
                  color: 'white',
                  padding: '4px 8px',
                  borderRadius: '4px',
                  fontSize: '12px'
                }}>
                  Main Image
                </div>
              </div>
            </div>
          )}
        </Card>

        {/* Pricing & Inventory */}
        <Card title="Pricing & Inventory" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            {formFields.slice(6, 12).map((field, index) => (
              <Col span={field.span} key={index}>
                <Form.Item
                  name={field.name}
                  label={field.label}
                  rules={field.rules}
                >
                  {field.component}
                </Form.Item>
              </Col>
            ))}
          </Row>
        </Card>

        {/* Physical Properties */}
        <Card title="Physical Properties" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            {formFields.slice(12, 15).map((field, index) => (
              <Col span={field.span} key={index}>
                <Form.Item
                  name={field.name}
                  label={field.label}
                  rules={field.rules}
                >
                  {field.component}
                </Form.Item>
              </Col>
            ))}
          </Row>
        </Card>

        {/* Tags */}
        <Card title="Tags" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 16 }}>
            <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
              <Select
                mode="combobox"
                placeholder="Search or add tags"
                value={tagSearchValue}
                onSearch={handleTagSearch}
                onSelect={handleTagSelect}
                style={{ flex: 1 }}
                notFoundContent={
                  <div style={{ textAlign: 'center', padding: '10px' }}>
                    No tags found
                  </div>
                }
              >
                {availableTags
                  .filter(tag => !selectedTags.find(t => t.id === tag.id))
                  .map(tag => (
                    <Option key={tag.id} value={tag.name}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <div 
                          style={{ 
                            width: 12, 
                            height: 12, 
                            backgroundColor: tag.color, 
                            borderRadius: '50%' 
                          }} 
                        />
                        {tag.name}
                      </div>
                    </Option>
                  ))}
              </Select>
              <Button 
                type="dashed" 
                icon={<PlusOutlined />}
                onClick={() => setIsTagModalVisible(true)}
                style={{ minWidth: '120px' }}
              >
                Create Tag
              </Button>
            </div>
          </div>
          
          <div>
            <Space wrap>
              {selectedTags.map(tag => (
                <AntTag
                  key={tag.id}
                  closable
                  color={tag.color}
                  onClose={() => handleTagRemove(tag.id)}
                >
                  {tag.name}
                </AntTag>
              ))}
            </Space>
          </div>
        </Card>

        {/* Description */}
        <Card title="Description" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            {formFields.slice(15, 17).map((field, index) => (
              <Col span={field.span} key={index}>
                <Form.Item
                  name={field.name}
                  label={field.label}
                  rules={field.rules}
                >
                  {field.component}
                </Form.Item>
              </Col>
            ))}
          </Row>
        </Card>


        {/* Status & Features */}
        <Card title="Status & Features" style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            <Col span={6}>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <Form.Item name="is_active" valuePropName="checked" noStyle>
                  <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
                </Form.Item>
                <span style={{ marginLeft: 8 }}>Active</span>
              </div>
            </Col>
            <Col span={6}>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <Form.Item name="is_featured" valuePropName="checked" noStyle>
                  <Switch checkedChildren="Featured" unCheckedChildren="Regular" />
                </Form.Item>
                <span style={{ marginLeft: 8 }}>Featured</span>
              </div>
            </Col>
            <Col span={6}>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <Form.Item name="is_digital" valuePropName="checked" noStyle>
                  <Switch checkedChildren="Digital" unCheckedChildren="Physical" />
                </Form.Item>
                <span style={{ marginLeft: 8 }}>Digital Product</span>
              </div>
            </Col>
            <Col span={6}>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <Form.Item name="requires_prescription" valuePropName="checked" noStyle>
                  <Switch checkedChildren="Required" unCheckedChildren="Not Required" />
                </Form.Item>
                <span style={{ marginLeft: 8 }}>Requires Prescription</span>
              </div>
            </Col>
          </Row>
        </Card>


        {/* Submit Button */}
        <Form.Item>
          <Button type="primary" htmlType="submit" loading={loading} size="large">
            {isEdit ? 'Update Product' : 'Create Product'}
          </Button>
        </Form.Item>
      </Form>

      {/* Create Tag Modal */}
      <Modal
        title="Create New Tag"
        open={isTagModalVisible}
        onOk={handleCreateTag}
        onCancel={() => {
          setIsTagModalVisible(false);
          newTagForm.resetFields();
        }}
        okText="Create Tag"
        cancelText="Cancel"
      >
        <Form form={newTagForm} layout="vertical">
          <Form.Item
            name="name"
            label="Tag Name"
            rules={[{ required: true, message: 'Please enter tag name' }]}
          >
            <Input placeholder="Enter tag name" />
          </Form.Item>
          <Form.Item
            name="description"
            label="Description"
          >
            <TextArea rows={2} placeholder="Enter tag description" />
          </Form.Item>
          <Form.Item
            name="color"
            label="Color"
            initialValue="#007bff"
          >
            <ColorPicker />
          </Form.Item>
        </Form>
      </Modal>

      {/* Image Preview Modal */}
      <Modal
        open={previewVisible}
        title="Image Preview"
        footer={null}
        onCancel={() => setPreviewVisible(false)}
      >
        <img alt="preview" style={{ width: '100%' }} src={previewImage} />
      </Modal>
    </div>
  );
};

export default ProductForm;



