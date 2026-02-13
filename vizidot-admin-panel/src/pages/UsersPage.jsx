import React from 'react';
import GenericCRUDTable from '../components/GenericCRUDTable';
import { Avatar, Image, Tag } from 'antd';
import { UserOutlined } from '@ant-design/icons';
import UserForm from './UserForm';

const UsersPage = () => {
  const userColumns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Photo',
      dataIndex: 'profile_image',
      key: 'profile_image',
      width: 80,
      render: (imageUrl) => {
        if (imageUrl) {
          return (
            <Image
              src={imageUrl}
              alt="Profile"
              width={40}
              height={40}
              style={{ borderRadius: '50%', objectFit: 'cover' }}
              preview={{ mask: 'Preview' }}
            />
          );
        }
        return (
          <Avatar
            size={40}
            icon={<UserOutlined />}
            style={{ backgroundColor: '#87d068' }}
          />
        );
      },
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
    {
      title: 'Assigned Artists',
      dataIndex: 'assignedArtists',
      key: 'assignedArtists',
      render: (artists) => {
        if (!artists || artists.length === 0) {
          return <span style={{ color: '#999' }}>None</span>;
        }
        return (
          <div>
            {artists.map(artist => (
              <Tag key={artist.artist_id} color="blue" style={{ marginBottom: 4 }}>
                {artist.name}
              </Tag>
            ))}
          </div>
        );
      },
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
      rules: [{ required: true, message: 'Please enter email' }],
      disabled: true, // Email is not editable
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
        customFormComponent={UserForm}
        defaultPageSize={20}
        searchPlaceholder="Search users..."
        showAddButton={false}
      />
    </div>
  );
};

export default UsersPage;
