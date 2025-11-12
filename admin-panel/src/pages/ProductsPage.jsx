import React from 'react';
import { useLocation } from 'react-router-dom';
import GenericCRUDTable from '../components/GenericCRUDTable';
import ProductForm from '../components/ProductForm';

const ProductsPage = () => {
  const location = useLocation();
  const productColumns = [
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
      width: 120,
      render: (image, record) => {
        // Use thumbnail if available, otherwise use main image
        const imageUrl = record.thumbnail || image;
        
        if (!imageUrl) {
          return (
            <div 
              style={{ 
              width: 80, 
              height: 80, 
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
          );
        }

        // Handle different image URL formats
        let finalImageUrl = imageUrl;
        if (!imageUrl.startsWith('http') && !imageUrl.startsWith('/uploads/')) {
          finalImageUrl = `/uploads/${imageUrl}`;
        }

        return (
          <div style={{ position: 'relative', width: 80, height: 80 }}>
            <img 
              src={finalImageUrl} 
              alt="Product" 
              style={{ 
                width: 80, 
                height: 80, 
                objectFit: 'cover', 
                borderRadius: 4 
              }} 
              onError={(e) => {
                // Hide the broken image and show placeholder
                try {
                  if (e.target && e.target.style) {
                    e.target.style.display = 'none';
                  }
                  const placeholder = e.target?.nextSibling;
                  if (placeholder && placeholder.style) {
                    placeholder.style.display = 'flex';
                  }
                } catch (error) {
                  console.warn('Error handling image load failure:', error);
                }
              }}
            />
            <div 
              style={{ 
                position: 'absolute',
                top: 0,
                left: 0,
                width: 80, 
                height: 80, 
                backgroundColor: '#f0f0f0', 
                borderRadius: 4,
                display: 'none',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 12,
                color: '#999'
              }}
            >
              No Image
            </div>
          </div>
        );
      },
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      sorter: true,
      render: (_, record) => {
        const displayName = record?.name
          ?? record?.title
          ?? record?.product_name
          ?? record?.Product?.name
          ?? record?.Name
          ?? '-';
        return (
          <div>
            <div style={{ fontWeight: 'bold' }}>{displayName}</div>
            {record?.brand?.name && (
              <div style={{ fontSize: 12, color: '#666' }}>
                Brand: {record.brand.name}
              </div>
            )}
          </div>
        );
      },
    },
    {
      title: 'SKU',
      dataIndex: 'sku',
      key: 'sku',
      width: 120,
      render: (sku) => sku || '-',
    },
    {
      title: 'Price',
      dataIndex: 'price',
      key: 'price',
      width: 100,
      sorter: true,
      render: (price, record) => (
        <div>
          <div style={{ fontWeight: 'bold' }}>₨{price}</div>
          {record.old_price && record.old_price > price && (
            <div style={{ fontSize: 12, color: '#999', textDecoration: 'line-through' }}>
              ₨{record.old_price}
            </div>
          )}
        </div>
      ),
    },
    {
      title: 'Stock',
      dataIndex: 'stock_quantity',
      key: 'stock_quantity',
      width: 80,
      sorter: true,
      render: (stock, record) => (
        <span style={{ 
          color: stock <= record.min_stock_alert ? '#ff4d4f' : '#52c41a',
          fontWeight: 'bold'
        }}>
          {stock}
        </span>
      ),
    },
    {
      title: 'Tags',
      dataIndex: 'tags',
      key: 'tags',
      width: 150,
      render: (tags) => (
        <div>
          {tags && tags.length > 0 ? (
            tags.slice(0, 2).map(tag => (
              <span 
                key={tag.id}
                style={{ 
                  display: 'inline-block',
                  backgroundColor: tag.color,
                  color: 'white',
                  padding: '2px 6px',
                  borderRadius: 4,
                  fontSize: 10,
                  margin: '1px'
                }}
              >
                {tag.name}
              </span>
            ))
          ) : (
            <span style={{ color: '#999', fontSize: 12 }}>No tags</span>
          )}
          {tags && tags.length > 2 && (
            <span style={{ color: '#999', fontSize: 12 }}>+{tags.length - 2} more</span>
          )}
        </div>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 100,
      render: (isActive) => (
        <span style={{ 
          color: isActive ? '#52c41a' : '#ff4d4f',
          fontWeight: 'bold'
        }}>
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
      title: 'Featured',
      dataIndex: 'is_featured',
      key: 'is_featured',
      width: 100,
      render: (isFeatured) => (
        <span style={{ 
          color: isFeatured ? '#faad14' : '#999',
          fontWeight: 'bold'
        }}>
          {isFeatured ? 'Yes' : 'No'}
        </span>
      ),
    },
    {
      title: 'Created',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      sorter: true,
      render: (date) => {
        if (!date) return '-';
        const d = typeof date === 'string' || typeof date === 'number' ? new Date(date) : date;
        return isNaN(d.getTime()) ? '-' : d.toLocaleString();
      },
    },
  ];

  // Custom form component for products
  const CustomProductForm = ({ initialValues, onSubmit, loading, isEdit }) => {
    const defaults = {
      is_active: true,
      is_digital: true,
      is_featured: false,
      requires_prescription: false,
      min_stock_alert: 5,
      unit: 'piece'
    };
    const normalizeBooleans = (v = {}) => ({
      ...v,
      is_active: v.is_active !== undefined ? !!v.is_active : v.is_active,
      is_digital: v.is_digital !== undefined ? !!v.is_digital : v.is_digital,
      is_featured: v.is_featured !== undefined ? !!v.is_featured : v.is_featured,
      requires_prescription: v.requires_prescription !== undefined ? !!v.requires_prescription : v.requires_prescription,
    });
    const effectiveInitial = isEdit 
      ? normalizeBooleans(initialValues)
      : normalizeBooleans({ ...defaults, ...(initialValues || {}) });
    return (
      <ProductForm
        initialValues={effectiveInitial}
        onSubmit={onSubmit}
        loading={loading}
        isEdit={isEdit}
      />
    );
  };

  return (
    <div>
      <div className="page-header">
        <h1>Products Management</h1>
        <p>Manage all products in the system</p>
      </div>
      <GenericCRUDTable
        title="Products"
        endpoint={`/api/v1/admin/products${location.search || ''}`}
        columns={productColumns}
        customFormComponent={CustomProductForm}
        showBulkActions={true}
        defaultPageSize={20}
        searchPlaceholder="Search products..."
      />
    </div>
  );
};

export default ProductsPage;
