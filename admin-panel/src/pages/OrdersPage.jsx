import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';

const OrdersPage = () => {
  const orderColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Order Number',
      dataIndex: 'order_number',
      key: 'order_number',
    },
    {
      title: 'Customer',
      dataIndex: ['user', 'first_name'],
      key: 'customer',
      render: (text, record) => `${record.user?.first_name} ${record.user?.last_name}`,
    },
    {
      title: 'Business',
      dataIndex: ['business', 'business_name'],
      key: 'business',
    },
    {
      title: 'Status',
      dataIndex: 'order_status',
      key: 'order_status',
      render: (status) => (
        <span className={`status-tag status-${status}`}>
          {status.charAt(0).toUpperCase() + status.slice(1)}
        </span>
      ),
    },
    {
      title: 'Amount',
      dataIndex: 'total_amount',
      key: 'total_amount',
      render: (amount) => `₨${amount}`,
    },
    {
      title: 'Date',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date) => new Date(date).toLocaleDateString(),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h1>Orders Management</h1>
        <p>Manage all orders in the system</p>
      </div>
      <GenericCRUDTable
        title="Orders"
        endpoint="/api/v1/admin/orders"
        columns={orderColumns}
        formFields={[]}
        viewButton={true}
        defaultPageSize={20}
        searchPlaceholder="Search orders..."
      />
    </div>
  );
};

export default OrdersPage;
