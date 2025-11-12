import React, { useState } from 'react';
import { Modal } from 'antd';
import { Link } from 'react-router-dom';
import GenericCRUDTable from '../components/GenericCRUDTable';
import CategoryForm from '../components/CategoryForm';
import { apiService } from '../services/api';

const CategoriesPage = () => {
  // Removed inline modal-based management in favor of a dedicated page
  const [tableKey, setTableKey] = useState(0);

  const categoryColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (text, record) => (
        <div>
          <div style={{ fontWeight: 600 }}>{text}</div>
          {/* Quick link to products filtered by category */}
          <div style={{ marginTop: 4 }}>
            <Link to={`/products?category_id=${record.id}`}>View products</Link>
            <span style={{ margin: '0 8px' }}>|</span>
            <Link to={`/categories/${record.id}/products`}>Manage products</Link>
          </div>
        </div>
      )
    },
    {
      title: 'Slug',
      dataIndex: 'slug',
      key: 'slug',
    },
    {
      title: 'Thumbnail',
      dataIndex: 'thumbnail',
      key: 'thumbnail',
      render: (url) => url ? (<img src={url} alt="thumb" style={{ width: 48, height: 48, objectFit: 'cover', borderRadius: 6 }} />) : '-'
    },
    {
      title: 'Image',
      dataIndex: 'image',
      key: 'image',
      render: (url) => url ? (<img src={url} alt="img" style={{ width: 72, height: 48, objectFit: 'cover', borderRadius: 6 }} />) : '-'
    },
    {
      title: 'Business',
      dataIndex: ['business', 'business_name'],
      key: 'business',
    },
    {
      title: 'Sort Order',
      dataIndex: 'sort_order',
      key: 'sort_order',
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      key: 'is_active',
      render: (isActive) => (
        <span className={`status-tag ${isActive ? 'status-active' : 'status-inactive'}`}>
          {isActive ? 'Active' : 'Inactive'}
        </span>
      ),
    }
  ];

  return (
    <div>
      <div className="page-header">
        <h1>Categories Management</h1>
        <p>Manage all product categories</p>
      </div>
      <GenericCRUDTable
        key={tableKey}
        title="Categories"
        endpoint="/api/v1/admin/categories"
        columns={categoryColumns}
        customFormComponent={CategoryForm}
        viewButton={true}
        onView={(record) => {
          Modal.info({
            title: `Category: ${record.name}`,
            content: (
              <div style={{ display: 'flex', gap: 16, alignItems: 'center', marginTop: 12 }}>
                <div>
                  <div style={{ marginBottom: 8 }}>Thumbnail</div>
                  {record.thumbnail ? <img src={record.thumbnail} alt="thumb" style={{ width: 96, height: 96, objectFit: 'cover', borderRadius: 8 }} /> : '—'}
                </div>
                <div>
                  <div style={{ marginBottom: 8 }}>Image</div>
                  {record.image ? <img src={record.image} alt="img" style={{ width: 160, height: 96, objectFit: 'cover', borderRadius: 8 }} /> : '—'}
                </div>
              </div>
            )
          });
        }}
        defaultPageSize={20}
        searchPlaceholder="Search categories..."
      />

      {/* Inline modals removed; management moved to dedicated page */}
    </div>
  );
};

export default CategoriesPage;
