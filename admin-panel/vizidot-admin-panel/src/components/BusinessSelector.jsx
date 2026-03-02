import React from 'react';
import { Select, Space, Tag } from 'antd';
import { ShopOutlined } from '@ant-design/icons';
import { useBusiness } from '../contexts/BusinessContext';

const { Option } = Select;

const BusinessSelector = () => {
  const { 
    businesses, 
    selectedBusiness, 
    loading, 
    isSuperAdmin, 
    switchBusiness 
  } = useBusiness();


  if (!isSuperAdmin) {
    return null;
  }

  const handleBusinessChange = (businessId) => {
    const business = businesses.find(b => b.id === businessId);
    if (business) {
      switchBusiness(business);
    }
  };

  return (
    <Select
      value={selectedBusiness?.id}
      onChange={handleBusinessChange}
      loading={loading}
      placeholder="Select Business"
      style={{ width: 200 }}
      size="middle"
      suffixIcon={<ShopOutlined />}
      showSearch
      filterOption={(input, option) => {
        // Get the business name from the option value
        const business = businesses.find(b => b.id === option.value);
        if (business) {
          return business.business_name.toLowerCase().indexOf(input.toLowerCase()) >= 0;
        }
        return false;
      }}
    >
      {businesses.map(business => (
        <Option key={business.id} value={business.id}>
          <Space>
            <span>{business.business_name}</span>
            {business.id !== 'all' && (
              <Tag 
                color={business.is_active ? 'green' : 'red'} 
                size="small"
              >
                {business.is_active ? 'Active' : 'Inactive'}
              </Tag>
            )}
          </Space>
        </Option>
      ))}
    </Select>
  );
};

export default BusinessSelector;
