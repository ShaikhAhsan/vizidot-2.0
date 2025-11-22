import React, { useState, useEffect } from 'react';
import {
  Table, Button, Space, Modal, Form, Input, Select,
  message, Popconfirm, Tag, Card, Tooltip
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import { adminAPI, apiService } from '../services/api';

const GenericCRUDTable = ({
  title,
  endpoint,
  columns,
  formFields,
  customFormComponent: CustomFormComponent,
  transformData = (data) => data,
  onView,
  viewButton = false,
  showBulkActions = false,
  defaultPageSize = 10,
  searchPlaceholder = "Search..."
}) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [editingRecord, setEditingRecord] = useState(null);
  const [form] = Form.useForm();
  const [formKey, setFormKey] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(defaultPageSize);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');

  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      if (!cancelled) await fetchData();
    };
    run();
    return () => { cancelled = true; };
  }, [page, pageSize, search, endpoint]); // Refetch when deps change

  const fetchData = async () => {
    setLoading(true);
    try {
      // Build URL with pagination and search
      const glue = endpoint.includes('?') ? '&' : '?';
      const url = `${endpoint}${glue}page=${encodeURIComponent(page)}&limit=${encodeURIComponent(pageSize)}${search ? `&search=${encodeURIComponent(search)}` : ''}`;

      const result = await apiService.get(url);
      if (result.success) {
        setData(result.data || []);
        const meta = result.pagination;
        if (meta && typeof meta.total === 'number') {
          setTotal(meta.total);
        } else {
          setTotal((result.data || []).length);
        }
      }
    } catch (error) {
      console.error('Fetch error:', error);
      message.error('Failed to fetch data');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (values) => {
    try {
      const resourceName = endpoint.split('/').pop();
      const methodName = `create${resourceName.charAt(0).toUpperCase() + resourceName.slice(1)}`;
      
      let result;
      if (adminAPI[methodName]) {
        result = await adminAPI[methodName](transformData(values));
      } else {
        result = await apiService.post(endpoint, transformData(values));
      }
      
      if (result.success) {
        message.success('Record created successfully');
        setModalVisible(false);
        form.resetFields();
        fetchData();
      }
    } catch (error) {
      console.error('Create error:', error);
      message.error('Failed to create record');
    }
  };

  const handleUpdate = async (values) => {
    try {
      const resourceName = endpoint.split('/').pop();
      const methodName = `update${resourceName.charAt(0).toUpperCase() + resourceName.slice(1)}`;
      
      let result;
      if (adminAPI[methodName]) {
        result = await adminAPI[methodName](editingRecord.id, transformData(values));
      } else {
        result = await apiService.put(`${endpoint}/${editingRecord.id}`, transformData(values));
      }
      
      if (result.success) {
        message.success('Record updated successfully');
        setModalVisible(false);
        setEditingRecord(null);
        form.resetFields();
        fetchData();
      }
    } catch (error) {
      console.error('Update error:', error);
      message.error('Failed to update record');
    }
  };

  const handleDelete = async (record) => {
    try {
      const resourceName = endpoint.split('/').pop();
      const methodName = `delete${resourceName.charAt(0).toUpperCase() + resourceName.slice(1)}`;
      
      let result;
      if (adminAPI[methodName]) {
        result = await adminAPI[methodName](record.id);
      } else {
        result = await apiService.delete(`${endpoint}/${record.id}`);
      }
      
      if (result.success) {
        message.success('Record deleted successfully');
        fetchData();
      }
    } catch (error) {
      console.error('Delete error:', error);
      message.error('Failed to delete record');
    }
  };

  const showModal = (record = null) => {
    setEditingRecord(record);
    // Only manipulate local form instance when not using a custom form component
    if (!CustomFormComponent) {
      if (record) {
        form.setFieldsValue(record);
      } else {
        form.resetFields();
        try {
          const defaults = {};
          (formFields || []).forEach(field => {
            if (Object.prototype.hasOwnProperty.call(field, 'defaultValue')) {
              defaults[field.name] = field.defaultValue;
            }
          });
          if (Object.keys(defaults).length > 0) {
            form.setFieldsValue(defaults);
          }
        } catch (e) {
          // non-blocking
        }
      }
    }
    setFormKey(prev => prev + 1);
    setModalVisible(true);
  };

  const actionColumn = {
    title: 'Actions',
    key: 'actions',
    width: 150,
    render: (_, record) => (
      <Space size="small">
        {viewButton && onView && (
          <Tooltip title="View Details">
            <Button
              type="text"
              icon={<EyeOutlined />}
              onClick={() => onView(record)}
            />
          </Tooltip>
        )}
        <Tooltip title="Edit">
          <Button
            type="text"
            icon={<EditOutlined />}
            onClick={() => showModal(record)}
          />
        </Tooltip>
        <Tooltip title="Delete">
          <Popconfirm
            title="Are you sure to delete this record?"
            onConfirm={() => handleDelete(record)}
            okText="Yes"
            cancelText="No"
          >
            <Button type="text" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Tooltip>
      </Space>
    ),
  };

  const enhancedColumns = [...columns, actionColumn];

  return (
    <Card
      title={title}
      extra={
        <Space>
          <Input.Search
            placeholder={searchPlaceholder}
            allowClear
            onSearch={(val) => { setPage(1); setSearch(val.trim()); }}
            style={{ width: 260 }}
          />
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => showModal()}
          >
            Add New
          </Button>
        </Space>
      }
    >
      <Table
        columns={enhancedColumns}
        dataSource={data}
        loading={loading}
        rowKey="id"
        pagination={{ current: page, pageSize, total, onChange: (p, ps) => { setPage(p); setPageSize(ps); }, showTotal: (t) => `Total: ${t}` }}
        scroll={{ x: 800 }}
      />

      <Modal
        title={editingRecord ? `Edit ${title}` : `Create ${title}`}
        open={modalVisible}
        onCancel={() => {
          setModalVisible(false);
          setEditingRecord(null);
          form.resetFields();
        }}
        footer={null}
        width={CustomFormComponent ? 1200 : 600}
      >
        {CustomFormComponent ? (
          <CustomFormComponent
            key={formKey}
            initialValues={editingRecord}
            onSubmit={editingRecord ? handleUpdate : handleCreate}
            loading={loading}
            isEdit={!!editingRecord}
          />
        ) : (
          <Form
            form={form}
            layout="vertical"
            onFinish={editingRecord ? handleUpdate : handleCreate}
          >
            {formFields.map(field => {
              // Check if field should be disabled (can be a boolean or a function)
              const isDisabled = typeof field.disabled === 'function' 
                ? field.disabled(editingRecord) 
                : (field.disabled && !!editingRecord); // Only disable when editing if disabled is true
              
              return (
                <Form.Item
                  key={field.name}
                  label={field.label}
                  name={field.name}
                  rules={field.rules}
                >
                  {field.type === 'select' ? (
                    <Select
                      placeholder={field.placeholder}
                      options={field.options}
                      mode={field.mode}
                      disabled={isDisabled}
                    />
                  ) : field.type === 'textarea' ? (
                    <Input.TextArea
                      placeholder={field.placeholder}
                      rows={field.rows || 4}
                      disabled={isDisabled}
                    />
                  ) : field.type === 'number' ? (
                    <Input
                      type="number"
                      placeholder={field.placeholder}
                      min={field.min}
                      max={field.max}
                      disabled={isDisabled}
                    />
                  ) : field.type === 'color' ? (
                    <Input
                      type="color"
                      placeholder={field.placeholder}
                      defaultValue={field.defaultValue}
                      disabled={isDisabled}
                    />
                  ) : (
                    <Input 
                      placeholder={field.placeholder}
                      disabled={isDisabled}
                    />
                  )}
                </Form.Item>
              );
            })}
            
            <Form.Item>
              <Space>
                <Button type="primary" htmlType="submit">
                  {editingRecord ? 'Update' : 'Create'}
                </Button>
                <Button onClick={() => setModalVisible(false)}>
                  Cancel
                </Button>
              </Space>
            </Form.Item>
          </Form>
        )}
      </Modal>
    </Card>
  );
};

export default GenericCRUDTable;
