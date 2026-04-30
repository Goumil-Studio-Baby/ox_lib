import React from 'react';
import { Box, BoxProps } from '@mantine/core';

interface GlassProps extends BoxProps {
  children?: React.ReactNode;
  onClick?: () => void;
}

const Glass: React.FC<GlassProps> = ({ children, onClick, ...props }) => {
  return (
    <Box
      onClick={onClick}
      style={{
        background: 'var(--ox-bg-primary)',
        border: '1px solid var(--ox-border)',
        borderRadius: 'var(--ox-radius)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.08)',
        ...props.style,
      }}
      {...props}
    >
      {children}
    </Box>
  );
};

export default Glass;
