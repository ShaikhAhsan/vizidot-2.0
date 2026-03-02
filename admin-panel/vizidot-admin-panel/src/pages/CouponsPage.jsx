import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';

const CouponsPage = () => {
  const couponColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Code',
      dataIndex: 'code',
      key: 'code',
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: 'Type',
      dataIndex: 'coupon_type',
      key: 'coupon_type',
      render: (type) => (
        <span className={`status-tag status-${type}`}>
          {type.charAt(0).toUpperCase() + type.slice(1)}
        </span>
      ),
    },
    {
      title: 'Discount',
      dataIndex: 'discount_value',
      key: 'discount_value',
      render: (value, record) => {
        if (record.coupon_type === 'percentage') {
          return `${value}%`;
        }
        return `₨${value}`;
      },
    },
    {
      title: 'Usage',
      dataIndex: 'usage_count',
      key: 'usage_count',
      render: (count, record) => `${count}/${record.usage_limit || '∞'}`,
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
  ];

  const couponFormFields = [
    {
      name: 'code',
      label: 'Coupon Code',
      type: 'text',
      placeholder: 'Enter coupon code',
      rules: [{ required: true, message: 'Please enter coupon code' }]
    },
    {
      name: 'name',
      label: 'Coupon Name',
      type: 'text',
      placeholder: 'Enter coupon name',
      rules: [{ required: true, message: 'Please enter coupon name' }]
    },
    {
      name: 'description',
      label: 'Description',
      type: 'textarea',
      placeholder: 'Enter coupon description',
    },
    {
      name: 'coupon_type',
      label: 'Coupon Type',
      type: 'select',
      placeholder: 'Select coupon type',
      options: [
        { label: 'Percentage', value: 'percentage' },
        { label: 'Fixed Amount', value: 'fixed_amount' },
        { label: 'Free Delivery', value: 'free_delivery' }
      ],
      rules: [{ required: true, message: 'Please select coupon type' }]
    },
    {
      name: 'discount_value',
      label: 'Discount Value',
      type: 'number',
      placeholder: 'Enter discount value',
      min: 0,
      rules: [{ required: true, message: 'Please enter discount value' }]
    },
    {
      name: 'min_order_amount',
      label: 'Minimum Order Amount',
      type: 'number',
      placeholder: 'Enter minimum order amount',
      min: 0,
    },
    {
      name: 'usage_limit',
      label: 'Usage Limit',
      type: 'number',
      placeholder: 'Enter usage limit',
      min: 1,
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
        <h1>Coupons Management</h1>
        <p>Manage all discount coupons and promotions</p>
      </div>
      <GenericCRUDTable
        title="Coupons"
        endpoint="/api/v1/admin/coupons"
        columns={couponColumns}
        formFields={couponFormFields}
        defaultPageSize={20}
        searchPlaceholder="Search coupons..."
      />
    </div>
  );
};

export default CouponsPage;
