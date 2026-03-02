import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';
import BrandForm from '../components/BrandForm';

const BrandsPage = () => {
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
      sorter: true,
    },
    {
      title: 'Image',
      dataIndex: 'image',
      key: 'image',
      width: 100,
      render: (image) => (
        image ? (
          <img 
            src={image} 
            alt="Brand" 
            style={{ 
              width: 50, 
              height: 50, 
              objectFit: 'cover', 
              borderRadius: 4 
            }} 
          />
        ) : (
          <div 
            style={{ 
              width: 50, 
              height: 50, 
              backgroundColor: '#f0f0f0', 
              borderRadius: 4,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 12,
              color: '#999'
            }}
          >
            No Image
          </div>
        )
      ),
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      sorter: true,
      render: (text) => <strong>{text}</strong>,
    },
    {
      title: 'Slug',
      dataIndex: 'slug',
      key: 'slug',
      render: (text) => <code>{text}</code>,
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

  // Using custom BrandForm instead of schema-defined fields

  const transformData = (values) => {
    const toUrl = (v) => {
      if (!v) return null;
      if (typeof v === 'string') return v;
      const file = Array.isArray(v) ? v[0] : v;
      return file?.response?.data?.url || file?.url || null;
    };
    return {
      ...values,
      image: toUrl(values.image),
      brand_slider_image: toUrl(values.brand_slider_image)
    };
  };

  return (
    <div>
      <h1>Brand Management</h1>
      <p>Manage product brands and their information.</p>
      
      <GenericCRUDTable
        endpoint="/api/v1/admin/brands"
        columns={columns}
        customFormComponent={BrandForm}
        title="Brands"
        addButtonText="Add Brand"
        searchPlaceholder="Search brands..."
        showBulkActions={true}
        defaultPageSize={20}
        transformData={transformData}
      />
    </div>
  );
};

export default BrandsPage;










