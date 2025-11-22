import React from 'react';
import { Layout, Menu } from 'antd';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  DashboardOutlined,
  UserOutlined,
  ShopOutlined,
  ShoppingOutlined,
  AppstoreOutlined,
  GiftOutlined,
  StarOutlined,
  SettingOutlined,
  TagsOutlined,
  CrownOutlined,
  CustomerServiceOutlined,
  SoundOutlined,
  VideoCameraOutlined,
  ShopOutlined as MusicShopOutlined
} from '@ant-design/icons';

const { Sider } = Layout;

const Sidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const menuItems = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: 'Dashboard',
    },
    {
      key: '/users',
      icon: <UserOutlined />,
      label: 'Users',
    },
    {
      key: '/businesses',
      icon: <ShopOutlined />,
      label: 'Businesses',
    },
    {
      key: '/products',
      icon: <ShoppingOutlined />,
      label: 'Products',
    },
    {
      key: '/orders',
      icon: <AppstoreOutlined />,
      label: 'Orders',
    },
    {
      key: '/categories',
      icon: <AppstoreOutlined />,
      label: 'Categories',
    },
    {
      key: '/brands',
      icon: <CrownOutlined />,
      label: 'Brands',
    },
    {
      key: '/tags',
      icon: <TagsOutlined />,
      label: 'Tags',
    },
    {
      key: '/coupons',
      icon: <GiftOutlined />,
      label: 'Coupons',
    },
    {
      key: '/reviews',
      icon: <StarOutlined />,
      label: 'Reviews',
    },
    {
      type: 'divider',
    },
    {
      key: 'music-platform',
      icon: <CustomerServiceOutlined />,
      label: 'Music Platform',
      children: [
        {
          key: '/artists',
          icon: <UserOutlined />,
          label: 'Artists',
        },
        {
          key: '/albums',
          icon: <SoundOutlined />,
          label: 'Albums',
        },
        {
          key: '/brandings',
          icon: <CrownOutlined />,
          label: 'Brandings',
        },
        {
          key: '/shops',
          icon: <MusicShopOutlined />,
          label: 'Shops',
        },
      ],
    },
  ];

  const handleMenuClick = ({ key }) => {
    navigate(key);
  };

  return (
    <Sider
      width={250}
      style={{
        background: '#fff',
        boxShadow: '2px 0 8px 0 rgba(29, 35, 41, 0.05)',
      }}
    >
      <div style={{
        padding: '24px',
        textAlign: 'center',
        borderBottom: '1px solid #f0f0f0',
        marginBottom: '16px'
      }}>
        <img 
          src="/logo.png" 
          alt="Vizidot Logo" 
          style={{ 
            height: '40px', 
            width: 'auto',
            marginBottom: '8px'
          }} 
        />
        <h2 style={{ margin: 0, color: '#1890ff', fontSize: '16px' }}>Vizidot Admin</h2>
      </div>
      
      <Menu
        mode="inline"
        selectedKeys={[location.pathname]}
        items={menuItems}
        onClick={handleMenuClick}
        style={{
          border: 'none',
          background: 'transparent'
        }}
      />
    </Sider>
  );
};

export default Sidebar;
