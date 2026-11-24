import { createRoot } from 'react-dom/client'
import { Suspense, useState, lazy} from 'react';
import { createPortal } from 'react-dom';
//import Fruits from './Fruits'

const Fruits = lazy(() => import('./Fruits'));

function MyApp(){
  return(
  <Suspense fallback={<div>Loading...</div>}>
    <Fruits />
  </Suspense>
  );
}

createRoot(document.getElementById('root')).render(

  <MyApp />
)
