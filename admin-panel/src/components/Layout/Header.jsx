import React from 'react';
import { Layout, Button, Dropdown, Avatar, Space } from 'antd';
import { UserOutlined, LogoutOutlined, SettingOutlined } from '@ant-design/icons';
import { useFirebaseAuth } from '../../contexts/FirebaseAuthContext';
import BusinessSelector from '../BusinessSelector';

const { Header: AntHeader } = Layout;

const Header = () => {
  const { userProfile, signOut } = useFirebaseAuth();

  const handleLogout = () => {
    signOut();
  };

  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Profile',
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: 'Settings',
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
      onClick: handleLogout,
    },
  ];

  return (
    <AntHeader style={{
      background: '#fff',
      boxShadow: '0 2px 8px 0 rgba(29, 35, 41, 0.05)',
      padding: '0 24px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <img 
          src="/logo.png" 
          alt="Vizidot Logo" 
          style={{ 
            height: '32px', 
            width: 'auto'
          }} 
        />
        <h1 style={{ margin: 0, fontSize: '20px', fontWeight: '600' }}>
          Vizidot Admin Panel
        </h1>
      </div>
      
      <Space size="middle">
        <BusinessSelector />
        <Dropdown
          menu={{ items: userMenuItems }}
          placement="bottomRight"
          arrow
        >
          <Button type="text" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: '2px', padding: '8px 12px', height: 'auto' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Avatar 
                icon={<UserOutlined />} 
                size={24}
                style={{ 
                  minWidth: '24px', 
                  height: '24px', 
                  lineHeight: '24px',
                  fontSize: '12px'
                }}
              />
              <span style={{ fontWeight: '500', fontSize: '14px', lineHeight: '20px' }}>
                {userProfile?.first_name ? `${userProfile.first_name} ${userProfile.last_name}` : 'Admin'}
              </span>
            </div>
            {userProfile?.role && (
              <span style={{ 
                fontSize: '12px', 
                color: '#666', 
                textTransform: 'capitalize',
                marginLeft: '32px',
                lineHeight: '16px'
              }}>
                {userProfile.role.replace('_', ' ')}
              </span>
            )}
          </Button>
        </Dropdown>
      </Space>
    </AntHeader>
  );
};

export default Header;
