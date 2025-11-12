import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';

const UsersPage = () => {
  const userColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Name',
      dataIndex: 'first_name',
      key: 'name',
      render: (text, record) => `${record.first_name} ${record.last_name}`,
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
    },
    {
      title: 'Phone',
      dataIndex: 'phone',
      key: 'phone',
    },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      render: (role) => (
        <span className={`status-tag status-${role || 'customer'}`}>
          {role ? role.charAt(0).toUpperCase() + role.slice(1) : 'Customer'}
        </span>
      ),
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

  const userFormFields = [
    {
      name: 'first_name',
      label: 'First Name',
      type: 'text',
      placeholder: 'Enter first name',
      rules: [{ required: true, message: 'Please enter first name' }]
    },
    {
      name: 'last_name',
      label: 'Last Name',
      type: 'text',
      placeholder: 'Enter last name',
      rules: [{ required: true, message: 'Please enter last name' }]
    },
    {
      name: 'email',
      label: 'Email',
      type: 'text',
      placeholder: 'Enter email',
      rules: [{ required: true, message: 'Please enter email' }]
    },
    {
      name: 'phone',
      label: 'Phone',
      type: 'text',
      placeholder: 'Enter phone number',
    },
    {
      name: 'role',
      label: 'Role',
      type: 'select',
      placeholder: 'Select role',
      options: [
        { label: 'Customer', value: 'customer' },
        { label: 'Super Admin', value: 'super_admin' },
        { label: 'System Admin', value: 'system_admin' },
        { label: 'Business Owner', value: 'business_owner' },
        { label: 'Business Admin', value: 'business_admin' },
        { label: 'Business Manager', value: 'business_manager' },
        { label: 'Business Staff', value: 'business_staff' },
        { label: 'Business Rider', value: 'business_rider' }
      ],
      rules: [{ required: true, message: 'Please select role' }]
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
        <h1>Users Management</h1>
        <p>Manage all users in the system</p>
      </div>
      <GenericCRUDTable
        title="Users"
        endpoint="/api/v1/admin/users"
        columns={userColumns}
        formFields={userFormFields}
        defaultPageSize={20}
        searchPlaceholder="Search users..."
      />
    </div>
  );
};

export default UsersPage;
