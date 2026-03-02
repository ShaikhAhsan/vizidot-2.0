import React, { useState } from 'react';
import { Select, Input, Row, Col } from 'antd';
import { PhoneOutlined } from '@ant-design/icons';

const { Option } = Select;

// Country codes with flags and names
const countryCodes = [
  { code: '+92', country: 'Pakistan', flag: '🇵🇰', name: 'Pakistan (+92)' },
  { code: '+1', country: 'United States', flag: '🇺🇸', name: 'United States (+1)' },
  { code: '+44', country: 'United Kingdom', flag: '🇬🇧', name: 'United Kingdom (+44)' },
  { code: '+91', country: 'India', flag: '🇮🇳', name: 'India (+91)' },
  { code: '+86', country: 'China', flag: '🇨🇳', name: 'China (+86)' },
  { code: '+971', country: 'UAE', flag: '🇦🇪', name: 'UAE (+971)' },
  { code: '+966', country: 'Saudi Arabia', flag: '🇸🇦', name: 'Saudi Arabia (+966)' },
  { code: '+974', country: 'Qatar', flag: '🇶🇦', name: 'Qatar (+974)' },
  { code: '+965', country: 'Kuwait', flag: '🇰🇼', name: 'Kuwait (+965)' },
  { code: '+973', country: 'Bahrain', flag: '🇧🇭', name: 'Bahrain (+973)' },
  { code: '+968', country: 'Oman', flag: '🇴🇲', name: 'Oman (+968)' },
  { code: '+20', country: 'Egypt', flag: '🇪🇬', name: 'Egypt (+20)' },
  { code: '+90', country: 'Turkey', flag: '🇹🇷', name: 'Turkey (+90)' },
  { code: '+98', country: 'Iran', flag: '🇮🇷', name: 'Iran (+98)' },
  { code: '+93', country: 'Afghanistan', flag: '🇦🇫', name: 'Afghanistan (+93)' },
  { code: '+880', country: 'Bangladesh', flag: '🇧🇩', name: 'Bangladesh (+880)' },
  { code: '+94', country: 'Sri Lanka', flag: '🇱🇰', name: 'Sri Lanka (+94)' },
  { code: '+977', country: 'Nepal', flag: '🇳🇵', name: 'Nepal (+977)' },
  { code: '+975', country: 'Bhutan', flag: '🇧🇹', name: 'Bhutan (+975)' },
  { code: '+960', country: 'Maldives', flag: '🇲🇻', name: 'Maldives (+960)' }
];

const CountryPhoneInput = ({ 
  value = { countryCode: '+92', phone: '' }, 
  onChange, 
  placeholder = 'Enter phone number',
  disabled = false,
  size = 'large',
  style = {}
}) => {
  const [selectedCountry, setSelectedCountry] = useState(value.countryCode || '+92');
  const [phoneNumber, setPhoneNumber] = useState(value.phone || '');

  const handleCountryChange = (countryCode) => {
    setSelectedCountry(countryCode);
    if (onChange) {
      onChange({
        countryCode,
        phone: phoneNumber
      });
    }
  };

  const handlePhoneChange = (e) => {
    const phone = e.target.value;
    setPhoneNumber(phone);
    if (onChange) {
      onChange({
        countryCode: selectedCountry,
        phone
      });
    }
  };

  const formatPhoneNumber = (phone) => {
    // Remove all non-digit characters
    const digits = phone.replace(/\D/g, '');
    
    // Format based on country code
    switch (selectedCountry) {
      case '+92': // Pakistan
        if (digits.length <= 4) return digits;
        if (digits.length <= 7) return `${digits.slice(0, 4)}-${digits.slice(4)}`;
        return `${digits.slice(0, 4)}-${digits.slice(4, 7)}-${digits.slice(7, 11)}`;
      
      case '+1': // US/Canada
        if (digits.length <= 3) return digits;
        if (digits.length <= 6) return `(${digits.slice(0, 3)}) ${digits.slice(3)}`;
        return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6, 10)}`;
      
      case '+44': // UK
        if (digits.length <= 4) return digits;
        if (digits.length <= 7) return `${digits.slice(0, 4)} ${digits.slice(4)}`;
        return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7, 11)}`;
      
      default:
        return digits;
    }
  };

  const validatePhoneNumber = (phone, countryCode) => {
    const digits = phone.replace(/\D/g, '');
    
    switch (countryCode) {
      case '+92': // Pakistan
        return digits.length >= 10 && digits.length <= 11;
      case '+1': // US/Canada
        return digits.length === 10;
      case '+44': // UK
        return digits.length >= 10 && digits.length <= 11;
      case '+91': // India
        return digits.length === 10;
      case '+971': // UAE
        return digits.length >= 9 && digits.length <= 10;
      default:
        return digits.length >= 7 && digits.length <= 15;
    }
  };

  const isValid = validatePhoneNumber(phoneNumber, selectedCountry);

  return (
    <Row gutter={8} style={style}>
      <Col span={8}>
        <Select
          value={selectedCountry}
          onChange={handleCountryChange}
          style={{ width: '100%' }}
          size={size}
          disabled={disabled}
          showSearch
          filterOption={(input, option) =>
            option.children.toLowerCase().indexOf(input.toLowerCase()) >= 0
          }
        >
          {countryCodes.map(country => (
            <Option key={country.code} value={country.code}>
              {country.flag} {country.name}
            </Option>
          ))}
        </Select>
      </Col>
      <Col span={16}>
        <Input
          value={phoneNumber}
          onChange={handlePhoneChange}
          placeholder={placeholder}
          prefix={<PhoneOutlined />}
          size={size}
          disabled={disabled}
          status={phoneNumber && !isValid ? 'error' : ''}
          style={{
            borderColor: phoneNumber && !isValid ? '#ff4d4f' : undefined
          }}
        />
      </Col>
    </Row>
  );
};

export default CountryPhoneInput;
