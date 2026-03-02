import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';

const ReviewsPage = () => {
  const reviewColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'User',
      dataIndex: ['user', 'first_name'],
      key: 'user',
      render: (text, record) => `${record.user?.first_name} ${record.user?.last_name}`,
    },
    {
      title: 'Product',
      dataIndex: ['product', 'name'],
      key: 'product',
    },
    {
      title: 'Rating',
      dataIndex: 'rating',
      key: 'rating',
      render: (rating) => `${rating}/5`,
    },
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
    },
    {
      title: 'Verified',
      dataIndex: 'is_verified_purchase',
      key: 'is_verified_purchase',
      render: (isVerified) => (
        <span className={`status-tag ${isVerified ? 'status-active' : 'status-inactive'}`}>
          {isVerified ? 'Yes' : 'No'}
        </span>
      ),
    },
    {
      title: 'Approved',
      dataIndex: 'is_approved',
      key: 'is_approved',
      render: (isApproved) => (
        <span className={`status-tag ${isApproved ? 'status-active' : 'status-inactive'}`}>
          {isApproved ? 'Yes' : 'No'}
        </span>
      ),
    },
    {
      title: 'Date',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date) => new Date(date).toLocaleDateString(),
    },
  ];

  const reviewFormFields = [
    {
      name: 'rating',
      label: 'Rating',
      type: 'select',
      placeholder: 'Select rating',
      options: [
        { label: '1 Star', value: 1 },
        { label: '2 Stars', value: 2 },
        { label: '3 Stars', value: 3 },
        { label: '4 Stars', value: 4 },
        { label: '5 Stars', value: 5 }
      ],
      rules: [{ required: true, message: 'Please select rating' }]
    },
    {
      name: 'title',
      label: 'Review Title',
      type: 'text',
      placeholder: 'Enter review title',
    },
    {
      name: 'comment',
      label: 'Comment',
      type: 'textarea',
      placeholder: 'Enter review comment',
    },
    {
      name: 'is_approved',
      label: 'Approved',
      type: 'select',
      placeholder: 'Select approval status',
      options: [
        { label: 'Approved', value: true },
        { label: 'Not Approved', value: false }
      ],
      rules: [{ required: true, message: 'Please select approval status' }]
    }
  ];

  return (
    <div>
      <div className="page-header">
        <h1>Reviews Management</h1>
        <p>Manage all product and business reviews</p>
      </div>
      <GenericCRUDTable
        title="Reviews"
        endpoint="/api/v1/admin/reviews"
        columns={reviewColumns}
        formFields={reviewFormFields}
        defaultPageSize={20}
        searchPlaceholder="Search reviews..."
      />
    </div>
  );
};

export default ReviewsPage;
