import React, { useRef, useEffect, useState } from 'react';
import { Button } from '../ui/Button';
import { RotateCcw, Check, PenTool } from 'lucide-react';

interface SignatureCanvasProps {
  onSignatureChange: (signature: string) => void;
  value?: string;
  required?: boolean;
}

export const SignatureCanvas: React.FC<SignatureCanvasProps> = ({
  onSignatureChange,
  value,
  required = false,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [isEmpty, setIsEmpty] = useState(!value);
  const [lastPoint, setLastPoint] = useState<{ x: number; y: number } | null>(null);
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
    return () => {
      setIsMounted(false);
    };
  }, []);

  useEffect(() => {
    if (!isMounted) return;
    
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    
    ctx.scale(dpr, dpr);
    
    ctx.strokeStyle = '#000000';
    ctx.lineWidth = 2;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.imageSmoothingEnabled = true;

    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, canvas.width / dpr, canvas.height / dpr);

    if (value && value !== '') {
      const img = new Image();
      img.onload = () => {
        if (isMounted && canvasRef.current) {
          ctx.drawImage(img, 0, 0, canvas.width / dpr, canvas.height / dpr);
          setIsEmpty(false);
        }
      };
      img.src = value;
    }
  }, [value, isMounted]);

  const getCoordinates = (e: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };

    const rect = canvas.getBoundingClientRect();
    let clientX, clientY;

    if ('touches' in e) {
      clientX = e.touches[0].clientX;
      clientY = e.touches[0].clientY;
    } else {
      clientX = e.clientX;
      clientY = e.clientY;
    }

    return {
      x: clientX - rect.left,
      y: clientY - rect.top,
    };
  };

  const startDrawing = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isMounted) return;
    e.preventDefault();
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    setIsDrawing(true);
    setIsEmpty(false);

    const { x, y } = getCoordinates(e);
    setLastPoint({ x, y });

    ctx.beginPath();
    ctx.moveTo(x, y);
  };

  const draw = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isDrawing || !lastPoint || !isMounted) return;
    e.preventDefault();

    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const { x, y } = getCoordinates(e);

    ctx.beginPath();
    ctx.moveTo(lastPoint.x, lastPoint.y);
    ctx.lineTo(x, y);
    ctx.stroke();

    setLastPoint({ x, y });
  };

  const stopDrawing = () => {
    if (!isDrawing || !isMounted) return;
    setIsDrawing(false);
    setLastPoint(null);
    saveSignature();
  };

  const saveSignature = () => {
    if (!isMounted) return;
    const canvas = canvasRef.current;
    if (!canvas) return;

    try {
      const rawSignature = canvas.toDataURL('image/png', 1.0);
      
      import('../../utils/optimizedImageProcessor').then(({ OptimizedImageProcessor }) => {
        if (!isMounted) return;
        OptimizedImageProcessor.processSignature(rawSignature).then(compressedSignature => {
          if (isMounted) {
            onSignatureChange(compressedSignature);
            setIsEmpty(false);
          }
        }).catch(() => {
          if (isMounted) {
            onSignatureChange(rawSignature);
            setIsEmpty(false);
          }
        });
      }).catch(() => {
        if (isMounted) {
          onSignatureChange(rawSignature);
          setIsEmpty(false);
        }
      });
      
    } catch (error) {
      if (isMounted) {
        onSignatureChange('');
        setIsEmpty(true);
      }
    }
  };

  const clearSignature = () => {
    if (!isMounted) return;
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    setIsEmpty(true);
    onSignatureChange('');
  };

  if (!isMounted) {
    return <div className="h-32 bg-gray-100 animate-pulse rounded" />;
  }

  return (
    <div className="space-y-3">
      <div className="border-2 border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 p-4">
        <div className="relative">
          <canvas
            ref={canvasRef}
            className="w-full h-32 border border-gray-200 dark:border-gray-700 rounded cursor-crosshair bg-white"
            style={{ 
              touchAction: 'none',
              width: '100%',
              height: '128px'
            }}
            onMouseDown={startDrawing}
            onMouseMove={draw}
            onMouseUp={stopDrawing}
            onMouseLeave={stopDrawing}
            onTouchStart={startDrawing}
            onTouchMove={draw}
            onTouchEnd={stopDrawing}
          />
          
          {isEmpty && (
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
              <div className="flex items-center space-x-2 text-gray-400">
                <PenTool className="h-5 w-5" />
                <span className="text-sm">Signez ici</span>
              </div>
            </div>
          )}
        </div>
        
        <div className="flex justify-between items-center mt-3">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            {isEmpty ? 'Dessinez votre signature ci-dessus' : 'Signature enregistrée ✓'}
          </p>
          <div className="flex space-x-2">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={clearSignature}
              className="flex items-center space-x-1"
            >
              <RotateCcw className="h-4 w-4" />
              <span>Effacer</span>
            </Button>
            {!isEmpty && (
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={saveSignature}
                className="flex items-center space-x-1 text-green-600"
              >
                <Check className="h-4 w-4" />
                <span>Valider</span>
              </Button>
            )}
          </div>
        </div>
      </div>
      
      {required && isEmpty && (
        <p className="text-sm text-red-600">
          La signature est obligatoire
        </p>
      )}
    </div>
  );
};
