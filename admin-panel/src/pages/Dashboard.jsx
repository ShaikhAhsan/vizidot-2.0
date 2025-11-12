import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Statistic, Table, Tag, Spin } from 'antd';
import { 
  UserOutlined, 
  ShopOutlined, 
  ShoppingOutlined, 
  DollarOutlined,
  TrophyOutlined,
  EyeOutlined
} from '@ant-design/icons';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import { adminAPI } from '../services/api';
import { useBusiness } from '../contexts/BusinessContext';

const Dashboard = () => {
  const [loading, setLoading] = useState(true);
  const [dashboardData, setDashboardData] = useState(null);
  const { selectedBusiness } = useBusiness();

  useEffect(() => {
    fetchDashboardData();
  }, [selectedBusiness]); // Refetch when business selection changes

  const fetchDashboardData = async () => {
    try {
      const result = await adminAPI.getDashboardStats();
      if (result.success) {
        setDashboardData(result.data);
      }
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <Spin size="large" />
      </div>
    );
  }

  const { overview, recentOrders, topProducts } = dashboardData || {};

  const recentOrdersColumns = [
    {
      title: 'Order ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
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
      key: 'status',
      render: (status) => (
        <Tag className={`status-tag status-${status}`}>
          {status.charAt(0).toUpperCase() + status.slice(1)}
        </Tag>
      ),
    },
    {
      title: 'Amount',
      dataIndex: 'total_amount',
      key: 'amount',
      render: (amount) => `₨${amount}`,
    },
    {
      title: 'Date',
      dataIndex: 'created_at',
      key: 'date',
      render: (date) => new Date(date).toLocaleDateString(),
    },
  ];

  const topProductsColumns = [
    {
      title: 'Product',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: 'Business',
      dataIndex: ['business', 'business_name'],
      key: 'business',
    },
    {
      title: 'Sales',
      dataIndex: 'total_sales',
      key: 'sales',
    },
    {
      title: 'Rating',
      dataIndex: 'rating',
      key: 'rating',
      render: (rating) => `${rating}/5`,
    },
  ];

  // Sample chart data (in real app, this would come from API)
  const salesData = [
    { name: 'Jan', sales: 4000, orders: 240 },
    { name: 'Feb', sales: 3000, orders: 139 },
    { name: 'Mar', sales: 2000, orders: 980 },
    { name: 'Apr', sales: 2780, orders: 390 },
    { name: 'May', sales: 1890, orders: 480 },
    { name: 'Jun', sales: 2390, orders: 380 },
  ];

  return (
    <div>
      <div className="page-header">
        <h1>Dashboard</h1>
        <p>Overview of your eBazar platform</p>
      </div>

      {/* Statistics Cards */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Users"
              value={overview?.totalUsers || 0}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#3f8600' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Businesses"
              value={overview?.totalBusinesses || 0}
              prefix={<ShopOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Orders"
              value={overview?.totalOrders || 0}
              prefix={<ShoppingOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Revenue"
              value={overview?.totalRevenue || 0}
              prefix={<DollarOutlined />}
              valueStyle={{ color: '#cf1322' }}
              formatter={(value) => `₨${value}`}
            />
          </Card>
        </Col>
      </Row>

      {/* Charts */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={12}>
          <Card title="Sales Trend" className="chart-container">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={salesData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Line type="monotone" dataKey="sales" stroke="#8884d8" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="Orders Trend" className="chart-container">
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={salesData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="orders" fill="#82ca9d" />
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>

      {/* Recent Orders and Top Products */}
      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="Recent Orders" className="recent-orders">
            <Table
              columns={recentOrdersColumns}
              dataSource={recentOrders || []}
              pagination={false}
              size="small"
              rowKey="id"
            />
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="Top Selling Products" className="recent-orders">
            <Table
              columns={topProductsColumns}
              dataSource={topProducts || []}
              pagination={false}
              size="small"
              rowKey="id"
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default Dashboard;
