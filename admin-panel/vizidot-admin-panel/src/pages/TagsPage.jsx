import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';

const TagsPage = () => {
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
      sorter: true,
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      sorter: true,
      render: (text, record) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div 
            style={{ 
              width: 12, 
              height: 12, 
              backgroundColor: record.color, 
              borderRadius: '50%',
              border: '1px solid #d9d9d9'
            }} 
          />
          <strong>{text}</strong>
        </div>
      ),
    },
    {
      title: 'Color',
      dataIndex: 'color',
      key: 'color',
      width: 100,
      render: (color) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div 
            style={{ 
              width: 20, 
              height: 20, 
              backgroundColor: color, 
              borderRadius: 4,
              border: '1px solid #d9d9d9'
            }} 
          />
          <code style={{ fontSize: 12 }}>{color}</code>
        </div>
      ),
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
      render: (text) => text || '-',
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 100,
      render: (isActive) => (
        <span 
          style={{ 
            color: isActive ? '#52c41a' : '#ff4d4f',
            fontWeight: 'bold'
          }}
        >
          {isActive ? 'Active' : 'Inactive'}
        </span>
      ),
      filters: [
        { text: 'Active', value: true },
        { text: 'Inactive', value: false },
      ],
      onFilter: (value, record) => record.is_active === value,
    },
    {
      title: 'Created',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 120,
      sorter: true,
      render: (date) => new Date(date).toLocaleDateString(),
    },
  ];

  const formFields = [
    {
      name: 'name',
      label: 'Tag Name',
      type: 'text',
      required: true,
      rules: [
        { required: true, message: 'Please enter tag name' },
        { min: 2, message: 'Name must be at least 2 characters' },
        { max: 50, message: 'Name must be at most 50 characters' },
        { pattern: /^[A-Za-z0-9\s\-&]+$/, message: 'Only letters, numbers, spaces, - and & allowed' }
      ],
      placeholder: 'Enter tag name',
    },
    {
      name: 'description',
      label: 'Description',
      type: 'textarea',
      placeholder: 'Enter tag description',
      rows: 3,
    },
    {
      name: 'color',
      label: 'Color',
      type: 'color',
      defaultValue: '#007bff',
      help: 'Choose a color for this tag',
    },
    {
      name: 'is_active',
      label: 'Status',
      type: 'select',
      options: [
        { value: true, label: 'Active' },
        { value: false, label: 'Inactive' },
      ],
      defaultValue: true,
    },
  ];

  return (
    <div>
      <h1>Tag Management</h1>
      <p>Manage product tags for categorization and filtering.</p>
      
      <GenericCRUDTable
        endpoint="/api/v1/admin/tags"
        columns={columns}
        formFields={formFields}
        transformData={(values) => ({
          ...values,
          name: values.name ? values.name.trim() : values.name,
          is_active: values.is_active === undefined ? true : values.is_active,
          color: values.color || '#007bff'
        })}
        title="Tags"
        addButtonText="Add Tag"
        searchPlaceholder="Search tags..."
        showBulkActions={true}
        defaultPageSize={20}
      />
    </div>
  );
};

export default TagsPage;










