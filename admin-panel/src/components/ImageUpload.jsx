import React, { useState } from 'react';
import { Button, Upload, message, Image, Avatar } from 'antd';
import { UploadOutlined, DeleteOutlined, UserOutlined } from '@ant-design/icons';
import { useFirebaseAuth } from '../contexts/FirebaseAuthContext';

/**
 * Reusable Image Upload Component
 * Handles image upload to Firebase Storage with preview
 * 
 * @param {string} folder - Folder name in Firebase Storage (e.g., 'artists', 'brandings')
 * @param {string} value - Current image URL (for controlled component)
 * @param {function} onChange - Callback when image URL changes
 * @param {object} imageStyle - Custom styles for the preview image
 * @param {boolean} showPreview - Whether to show image preview (default: true)
 */
const ImageUpload = ({ 
  folder = 'artists', 
  value, 
  onChange, 
  imageStyle = {},
  showPreview = true 
}) => {
  const [uploading, setUploading] = useState(false);
  const { user } = useFirebaseAuth();

  const handleImageUpload = async (file) => {
    setUploading(true);
    try {
      if (!user) {
        message.error('Please log in to upload images');
        setUploading(false);
        return false;
      }
      
      const formData = new FormData();
      formData.append('image', file);
      
      // Get auth token from the authenticated user
      const token = await user.getIdToken();
      
      // Upload with folder parameter
      const response = await fetch(`/api/v1/upload/image?folder=${folder}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        body: formData,
      });

      const data = await response.json();

      if (response.ok && data.success) {
        const uploadedUrl = data.data.url;
        if (onChange) {
          onChange(uploadedUrl);
        }
        message.success('Image uploaded successfully');
        setUploading(false);
        return false; // Prevent default upload
      } else {
        const errorMsg = data.error || 'Image upload failed';
        console.error('Upload error:', errorMsg, data);
        message.error(errorMsg);
        setUploading(false);
        return false;
      }
    } catch (error) {
      console.error('Upload exception:', error);
      message.error(`Image upload failed: ${error.message}`);
      setUploading(false);
      return false;
    }
  };

  const defaultImageStyle = {
    maxWidth: '300px',
    maxHeight: '300px',
    objectFit: 'cover',
    borderRadius: '8px',
    marginBottom: '12px',
    ...imageStyle
  };

  return (
    <div>
      {showPreview && value ? (
        <div style={{ marginBottom: 16 }}>
          <Image
            src={value}
            alt="Upload preview"
            style={defaultImageStyle}
            preview={{
              mask: 'Preview'
            }}
          />
          <div>
            <Button
              icon={<DeleteOutlined />}
              danger
              onClick={() => {
                if (onChange) {
                  onChange('');
                }
              }}
              style={{ marginRight: 8 }}
            >
              Remove Image
            </Button>
            <Button
              icon={<UploadOutlined />}
              onClick={() => document.getElementById(`image-upload-input-${folder}`)?.click()}
              loading={uploading}
            >
              Change Image
            </Button>
          </div>
        </div>
      ) : (
        <Upload
          beforeUpload={handleImageUpload}
          showUploadList={false}
          accept="image/*"
        >
          <Button icon={<UploadOutlined />} loading={uploading}>
            Upload Image
          </Button>
        </Upload>
      )}
      <input
        id={`image-upload-input-${folder}`}
        type="file"
        accept="image/*"
        style={{ display: 'none' }}
        onChange={(e) => {
          if (e.target.files && e.target.files[0]) {
            handleImageUpload(e.target.files[0]);
          }
        }}
      />
    </div>
  );
};

export default ImageUpload;

