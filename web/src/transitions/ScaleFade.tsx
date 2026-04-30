import { AnimatePresence, motion } from 'framer-motion';
import { useConfig } from '../providers/ConfigProvider';

const VARIANTS = {
  slide: {
    initial: { opacity: 0, y: -12, scale: 0.95 },
    animate: { opacity: 1, y: 0, scale: 1 },
    exit:    { opacity: 0, y: -12, scale: 0.95 },
  },
  fade: {
    initial: { opacity: 0 },
    animate: { opacity: 1 },
    exit:    { opacity: 0 },
  },
  scale: {
    initial: { opacity: 0, scale: 0.80 },
    animate: { opacity: 1, scale: 1 },
    exit:    { opacity: 0, scale: 0.80 },
  },
  bounce: {
    initial: { opacity: 0, scale: 0.70 },
    animate: { opacity: 1, scale: 1, transition: { type: 'spring', bounce: 0.45 } },
    exit:    { opacity: 0, scale: 0.70 },
  },
  none: {
    initial: {},
    animate: {},
    exit:    {},
  },
};

const SPEEDS = { fast: 0.10, normal: 0.20, slow: 0.36 };

const ScaleFade: React.FC<{
  visible: boolean;
  children: React.ReactNode;
  onExitComplete?: () => void;
}> = ({ visible, children, onExitComplete }) => {
  const { config } = useConfig();
  const disabled = config.disableAnimations;
  const style  = (disabled ? 'none' : (config.theme?.animationStyle ?? 'slide')) as keyof typeof VARIANTS;
  const dur    = SPEEDS[config.theme?.animationSpeed ?? 'normal'] ?? 0.20;
  const v      = VARIANTS[style] ?? VARIANTS.slide;

  return (
    <AnimatePresence onExitComplete={onExitComplete}>
      {visible && (
        <motion.div
          initial={v.initial}
          animate={{ ...v.animate, transition: { duration: dur, ease: [0, 0, 0.2, 1], ...(v.animate as any).transition } }}
          exit={{ ...v.exit, transition: { duration: dur * 0.6, ease: [0.4, 0, 1, 1] } }}
        >
          {children}
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default ScaleFade;
