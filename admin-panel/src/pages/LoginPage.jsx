import React, { useState } from 'react';
import { Form, Input, Button, Card, message, Divider } from 'antd';
import { UserOutlined, LockOutlined, GoogleOutlined } from '@ant-design/icons';
import { useFirebaseAuth } from '../contexts/FirebaseAuthContext';
import { useNavigate } from 'react-router-dom';

const LoginPage = () => {
  const [loading, setLoading] = useState(false);
  const [forgotPasswordLoading, setForgotPasswordLoading] = useState(false);
  const { signIn, signInWithGoogle, resetPassword, isAdmin, signOut } = useFirebaseAuth();
  const navigate = useNavigate();

  const onFinish = async (values) => {
    setLoading(true);
    try {
      const result = await signIn(values.email, values.password);
      if (result.success) {
        // If login succeeded, user is already verified as admin by the API
        navigate('/dashboard');
      } else {
        // Show the error message from the API
        if (result.error) {
          message.error(result.error);
          // Sign out silently if access was denied
          if (result.error.includes('privileges')) {
            await signOut(true);
          }
        } else {
          message.error('Login failed');
        }
      }
    } catch (error) {
      message.error(error.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setLoading(true);
    try {
      const result = await signInWithGoogle();
      if (result.success) {
        // If login succeeded, user is already verified as admin by the API
        navigate('/dashboard');
      } else {
        // Show the error message from the API
        if (result.error) {
          message.error(result.error);
          // Sign out silently if access was denied
          if (result.error.includes('privileges')) {
            await signOut(true);
          }
        } else {
          message.error('Google login failed');
        }
      }
    } catch (error) {
      message.error(error.message || 'Google login failed');
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    const email = prompt('Enter your email address:');
    if (email) {
      setForgotPasswordLoading(true);
      try {
        await resetPassword(email);
      } finally {
        setForgotPasswordLoading(false);
      }
    }
  };

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
    }}>
      <Card
        style={{ width: 400 }}
        headStyle={{ textAlign: 'center', fontSize: '24px', fontWeight: 'bold' }}
      >
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <img 
            src="/logo.png" 
            alt="Vizidot Logo" 
            style={{ 
              height: '80px', 
              width: 'auto',
              marginBottom: '16px'
            }} 
          />
          <h2 style={{ margin: 0, color: '#1890ff', fontSize: '20px', fontWeight: '600' }}>
            Vizidot Admin Panel
          </h2>
        </div>
        <Form
          name="login"
          onFinish={onFinish}
          autoComplete="off"
          layout="vertical"
        >
          <Form.Item
            name="email"
            rules={[{ required: true, message: 'Please input your email!' }]}
          >
            <Input
              prefix={<UserOutlined />}
              placeholder="Email"
              size="large"
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[{ required: true, message: 'Please input your password!' }]}
          >
            <Input.Password
              prefix={<LockOutlined />}
              placeholder="Password"
              size="large"
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: '8px' }}>
            <Button
              type="primary"
              htmlType="submit"
              loading={loading}
              size="large"
              style={{ width: '100%' }}
            >
              Login
            </Button>
          </Form.Item>

          <Form.Item style={{ marginBottom: 0, marginTop: 0, textAlign: 'right' }}>
            <Button
              type="link"
              onClick={handleForgotPassword}
              loading={forgotPasswordLoading}
              style={{ padding: 0 }}
            >
              Forgot Password?
            </Button>
          </Form.Item>

          <Divider>OR</Divider>

          <Form.Item>
            <Button
              icon={<GoogleOutlined />}
              onClick={handleGoogleLogin}
              loading={loading}
              size="large"
              style={{ width: '100%' }}
            >
              Login with Google
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
};

export default LoginPage;
