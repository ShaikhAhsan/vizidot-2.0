import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useFirebaseAuth } from './FirebaseAuthContext';
import { apiService } from '../services/api';

const ArtistContext = createContext();

export const useArtistContext = () => {
  const context = useContext(ArtistContext);
  if (!context) {
    throw new Error('useArtistContext must be used within an ArtistProvider');
  }
  return context;
};

// Alias for backward compatibility
export const useArtist = useArtistContext;

export const ArtistProvider = ({ children }) => {
  const [artists, setArtists] = useState([]);
  const [selectedArtist, setSelectedArtist] = useState(null);
  const [loading, setLoading] = useState(false);
  const { userProfile, isSuperAdmin } = useFirebaseAuth();

  // Fetch all artists (filtered by assigned artists if user is not super admin)
  const fetchArtists = useCallback(async () => {
    setLoading(true);
    try {
      let artistsToShow = [];
      
      // If user is super admin, show all artists
      if (isSuperAdmin()) {
        const response = await apiService.get('/api/v1/music/artists?limit=1000');
        if (response.success) {
          artistsToShow = response.data || [];
        }
      } else if (userProfile?.assignedArtists && userProfile.assignedArtists.length > 0) {
        // If user has assigned artists, only show those
        artistsToShow = userProfile.assignedArtists;
      } else {
        // No artists assigned, show empty list
        artistsToShow = [];
      }
      
      // Add "All Artists" option at the beginning
      const allArtistsOption = {
        artist_id: 'all',
        name: 'All Artists',
        is_active: true
      };
      setArtists([allArtistsOption, ...artistsToShow]);
      
      // Set "All Artists" as default if none selected
      if (!selectedArtist) {
        setSelectedArtist(allArtistsOption);
      }
    } catch (error) {
      console.error('Failed to fetch artists:', error);
    } finally {
      setLoading(false);
    }
  }, [isSuperAdmin, selectedArtist, userProfile]);

  // Switch artist context
  const switchArtist = (artist) => {
    setSelectedArtist(artist);
    // Store in localStorage for persistence
    localStorage.setItem('selectedArtist', JSON.stringify(artist));
  };

  // Get current artist context for API calls
  const getArtistContext = useCallback(() => {
    if (selectedArtist) {
      // If "All Artists" is selected, return null to show all data
      return selectedArtist.artist_id === 'all' ? null : selectedArtist.artist_id;
    }
    return null;
  }, [selectedArtist]);

  // Get artist context query parameter for API calls
  const getArtistQueryParam = useCallback(() => {
    const artistId = getArtistContext();
    return artistId ? { artist_id: artistId } : {};
  }, [getArtistContext]);

  // Load selected artist from localStorage on mount
  useEffect(() => {
    const savedArtist = localStorage.getItem('selectedArtist');
    if (savedArtist) {
      try {
        setSelectedArtist(JSON.parse(savedArtist));
      } catch (error) {
        console.error('Failed to parse saved artist:', error);
        localStorage.removeItem('selectedArtist');
      }
    }
  }, []);

  // Fetch artists on mount and when user profile changes
  useEffect(() => {
    fetchArtists();
  }, [fetchArtists]);

  const value = {
    artists,
    selectedArtist,
    loading,
    switchArtist,
    getArtistContext,
    getArtistQueryParam,
    fetchArtists
  };

  return (
    <ArtistContext.Provider value={value}>
      {children}
    </ArtistContext.Provider>
  );
};

