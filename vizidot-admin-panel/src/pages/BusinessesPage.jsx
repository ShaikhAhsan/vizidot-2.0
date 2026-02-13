import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';

const BusinessesPage = () => {
  const businessColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Business Name',
      dataIndex: 'business_name',
      key: 'business_name',
    },
    {
      title: 'Type',
      dataIndex: 'business_type',
      key: 'business_type',
      render: (type) => (
        <span className={`status-tag status-${type}`}>
          {type.charAt(0).toUpperCase() + type.slice(1)}
        </span>
      ),
    },
    {
      title: 'Rating',
      dataIndex: 'rating',
      key: 'rating',
      render: (rating) => `${rating}/5`,
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
    },
    {
      title: 'Verified',
      dataIndex: 'is_verified',
      key: 'is_verified',
      render: (isVerified) => (
        <span className={`status-tag ${isVerified ? 'status-active' : 'status-inactive'}`}>
          {isVerified ? 'Yes' : 'No'}
        </span>
      ),
    },
  ];

  const businessFormFields = [
    {
      name: 'business_name',
      label: 'Business Name',
      type: 'text',
      placeholder: 'Enter business name',
      rules: [{ required: true, message: 'Please enter business name' }]
    },
    {
      name: 'business_slug',
      label: 'Business Slug',
      type: 'text',
      placeholder: 'Enter business slug',
      rules: [{ required: true, message: 'Please enter business slug' }]
    },
    {
      name: 'description',
      label: 'Description',
      type: 'textarea',
      placeholder: 'Enter business description',
    },
    {
      name: 'business_type',
      label: 'Business Type',
      type: 'select',
      placeholder: 'Select business type',
      options: [
        { label: 'Grocery', value: 'grocery' },
        { label: 'Restaurant', value: 'restaurant' },
        { label: 'Pharmacy', value: 'pharmacy' },
        { label: 'Electronics', value: 'electronics' },
        { label: 'Clothing', value: 'clothing' },
        { label: 'Other', value: 'other' }
      ],
      rules: [{ required: true, message: 'Please select business type' }]
    },
    {
      name: 'contact_phone',
      label: 'Contact Phone',
      type: 'text',
      placeholder: 'Enter contact phone',
    },
    {
      name: 'contact_email',
      label: 'Contact Email',
      type: 'text',
      placeholder: 'Enter contact email',
    },
    {
      name: 'address',
      label: 'Address',
      type: 'textarea',
      placeholder: 'Enter business address',
    },
    {
      name: 'is_active',
      label: 'Active',
      type: 'select',
      placeholder: 'Select status',
      options: [
        { label: 'Active', value: true },
        { label: 'Inactive', value: false }
      ],
      rules: [{ required: true, message: 'Please select status' }]
    }
  ];

  return (
    <div>
      <div className="page-header">
        <h1>Businesses Management</h1>
        <p>Manage all businesses in the system</p>
      </div>
      <GenericCRUDTable
        title="Businesses"
        endpoint="/api/v1/admin/businesses"
        columns={businessColumns}
        formFields={businessFormFields}
        defaultPageSize={20}
        searchPlaceholder="Search businesses..."
      />
    </div>
  );
};

export default BusinessesPage;
