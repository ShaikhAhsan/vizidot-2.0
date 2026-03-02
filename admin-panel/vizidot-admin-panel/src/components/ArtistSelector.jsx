import React from 'react';
import { Select, Space, Tag } from 'antd';
import { UserOutlined } from '@ant-design/icons';
import { useArtist } from '../contexts/ArtistContext';

const { Option } = Select;

const ArtistSelector = () => {
  const { 
    artists, 
    selectedArtist, 
    loading, 
    switchArtist 
  } = useArtist();

  const handleArtistChange = (artistId) => {
    const artist = artists.find(a => a.artist_id === artistId);
    if (artist) {
      switchArtist(artist);
    }
  };

  return (
    <Select
      value={selectedArtist?.artist_id}
      onChange={handleArtistChange}
      loading={loading}
      placeholder="Select Artist"
      style={{ width: 200 }}
      size="middle"
      suffixIcon={<UserOutlined />}
      showSearch
      filterOption={(input, option) => {
        // Get the artist name from the option value
        const artist = artists.find(a => a.artist_id === option.value);
        if (artist) {
          return artist.name.toLowerCase().indexOf(input.toLowerCase()) >= 0;
        }
        return false;
      }}
    >
      {artists.map(artist => (
        <Option key={artist.artist_id} value={artist.artist_id}>
          <Space>
            <span>{artist.name}</span>
            {artist.artist_id !== 'all' && (
              <Tag 
                color={artist.is_active ? 'green' : 'red'} 
                size="small"
              >
                {artist.is_active ? 'Active' : 'Inactive'}
              </Tag>
            )}
          </Space>
        </Option>
      ))}
    </Select>
  );
};

export default ArtistSelector;

