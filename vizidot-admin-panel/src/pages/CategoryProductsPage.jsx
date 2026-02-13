import React, { useEffect, useState, useCallback } from 'react';
import { useSearchParams, useParams } from 'react-router-dom';
import { Card, List, Input, Checkbox, Tag, message } from 'antd';
import { apiService } from '../services/api';

const CategoryProductsPage = () => {
  const [searchParams] = useSearchParams();
  const params = useParams();
  const categoryId = params.id || searchParams.get('category_id');
  const [category, setCategory] = useState(null);
  const [products, setProducts] = useState([]);
  const [assignedIds, setAssignedIds] = useState(new Set());
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(false);
  const [toggling, setToggling] = useState(new Set());

  const buildImageUrl = (url) => {
    if (!url) return null;
    if (url.startsWith('http')) return url;
    if (url.startsWith('/uploads/')) return `http://localhost:8000${url}`;
    return `http://localhost:8000/uploads/${url}`;
  };

  const fetchData = useCallback(async () => {
    if (!categoryId) return;
    setLoading(true);
    try {
      const [catRes, assignedRes, allRes] = await Promise.all([
        apiService.get(`/api/v1/admin/categories/${categoryId}`),
        apiService.get(`/api/v1/admin/products?category_id=${encodeURIComponent(categoryId)}&limit=1000`),
        apiService.get(`/api/v1/admin/products?limit=1000`)
      ]);
      if (catRes.success) setCategory(catRes.data);
      if (allRes.success) setProducts(allRes.data || []);
      if (assignedRes.success) setAssignedIds(new Set((assignedRes.data || []).map(p => p.id)));
    } catch (e) {
      message.error('Failed to load products');
    } finally {
      setLoading(false);
    }
  }, [categoryId]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const toggleAssign = async (productId, willAssign) => {
    if (!categoryId) return;
    if (toggling.has(productId)) return;
    
    console.log(`Toggling product ${productId} to ${willAssign ? 'assigned' : 'unassigned'} for category ${categoryId}`);
    
    const newToggling = new Set(toggling);
    newToggling.add(productId);
    setToggling(newToggling);
    
    try {
      const endpoint = willAssign
        ? `/api/v1/admin/categories/${categoryId}/assign-products`
        : `/api/v1/admin/categories/${categoryId}/remove-products`;
      
      console.log(`Making request to: ${endpoint}`, { product_ids: [productId] });
      
      const res = await apiService.post(endpoint, { product_ids: [productId] });
      
      console.log('API response:', res);
      
      if (res.success) {
        const next = new Set(assignedIds);
        if (willAssign) {
          next.add(productId);
          message.success('Product added to category');
        } else {
          next.delete(productId);
          message.success('Product removed from category');
        }
        setAssignedIds(next);
      } else {
        message.error(res.error || 'Operation failed');
      }
    } catch (e) {
      console.error('Toggle assign error:', e);
      message.error(e.message || 'Operation failed');
    } finally {
      const after = new Set(toggling);
      after.delete(productId);
      setToggling(after);
    }
  };

  const filtered = products.filter(p => (p.name || '').toLowerCase().includes(search.toLowerCase()));

  return (
    <div>
      <div className="page-header">
        <h1>Manage Category Products</h1>
        <p>{category ? `${category.name} (ID: ${category.id})` : 'Loading category...'}</p>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <Input.Search placeholder="Search products" value={search} onChange={(e) => setSearch(e.target.value)} style={{ maxWidth: 360 }} />
        <div style={{ color: '#666' }}>{assignedIds.size} added / {products.length} total</div>
      </div>
      <List
        loading={loading}
        dataSource={filtered}
        rowKey="id"
        grid={{ gutter: 16, xs: 1, sm: 2, md: 3, lg: 4, xl: 5, xxl: 6 }}
        renderItem={(item) => {
          const isAssigned = assignedIds.has(item.id);
          const isBusy = toggling.has(item.id);
          const img = buildImageUrl(item.thumbnail || item.image);
          return (
            <List.Item>
              <Card
                hoverable
                style={{
                  borderColor: isAssigned ? '#52c41a' : undefined,
                  background: isAssigned ? 'rgba(82,196,26,0.08)' : undefined
                }}
                bodyStyle={{ padding: 12 }}
                cover={
                  <div style={{ position: 'relative', height: 160, overflow: 'hidden', backgroundColor: '#f5f5f5' }}>
                    {img ? (
                      <img
                        alt={item.name}
                        src={img}
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.nextSibling.style.display = 'flex';
                        }}
                      />
                    ) : null}
                    <div 
                      style={{ 
                        display: img ? 'none' : 'flex',
                        width: '100%', 
                        height: '100%', 
                        alignItems: 'center', 
                        justifyContent: 'center',
                        backgroundColor: '#f5f5f5',
                        color: '#999',
                        fontSize: '12px'
                      }}
                    >
                      No Image
                    </div>
                    {isAssigned && (
                      <Tag color="green" style={{ position: 'absolute', top: 8, left: 8 }}>Added</Tag>
                    )}
                    <div style={{ position: 'absolute', top: 8, right: 8 }}>
                      <Checkbox
                        checked={isAssigned}
                        disabled={isBusy}
                        onChange={(e) => toggleAssign(item.id, e.target.checked)}
                      />
                    </div>
                  </div>
                }
              >
                <div style={{ fontWeight: 600, marginBottom: 6 }}>{item.name || `#${item.id}`}</div>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                  <div style={{ fontSize: 16, fontWeight: 700 }}>₨{item.price}</div>
                  {item.old_price && item.old_price > item.price && (
                    <div style={{ color: '#999', textDecoration: 'line-through' }}>₨{item.old_price}</div>
                  )}
                </div>
                {item.brand?.name && (
                  <div style={{ marginTop: 4, color: '#666', fontSize: 12 }}>Brand: {item.brand.name}</div>
                )}
              </Card>
            </List.Item>
          );
        }}
      />
    </div>
  );
};

export default CategoryProductsPage;


