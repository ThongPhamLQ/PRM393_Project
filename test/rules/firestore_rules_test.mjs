// Node 18+, no npm dependencies. Run only against a local Firestore Emulator.
import assert from 'node:assert/strict';
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) throw Error('Local emulator required');
const project = process.env.GCLOUD_PROJECT || 'demo-prm393';
const root = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const path = (name) => `projects/${project}/databases/(default)/documents/${name}`;
function token(uid, email = `${uid}@example.com`) {
  const encode = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');
  return `${encode({alg:'none',typ:'JWT'})}.${encode({sub:uid,user_id:uid,email,
    aud:project,iss:`https://securetoken.google.com/${project}`,iat:Math.floor(Date.now()/1000),
    exp:Math.floor(Date.now()/1000)+3600,firebase:{sign_in_provider:'password'}})}.`;
}
const buyer = token('buyer');
const other = token('other');
const admin = token('admin', 'admin@cafe.com');
function value(v) {
  if (typeof v === 'number') return Number.isInteger(v) ? {integerValue:String(v)} : {doubleValue:v};
  if (typeof v === 'boolean') return {booleanValue:v};
  if (typeof v === 'string') return {stringValue:v};
  if (Array.isArray(v)) return {arrayValue:{values:v.map(value)}};
  return {mapValue:{fields:fields(v)}};
}
const fields = (data) => Object.fromEntries(Object.entries(data).map(([k,v]) => [k,value(v)]));
function write(name, data, {mask, timestamp} = {}) {
  return {update:{name:path(name),fields:fields(data)},
    ...(mask ? {updateMask:{fieldPaths:mask}} : {}),
    ...(timestamp ? {updateTransforms:[{fieldPath:timestamp,setToServerValue:'REQUEST_TIME'}]} :
      name.startsWith('orders/') && !mask ? {updateTransforms:[{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'}]} : {})};
}
async function commit(writes, auth = buyer) {
  return fetch(`${root}:commit`, {method:'POST',headers:{'Content-Type':'application/json',
    Authorization:`Bearer ${auth}`},body:JSON.stringify({writes})});
}
async function allowed(writes, auth = buyer) {
  const result = await commit(writes, auth);
  assert.equal(result.status, 200, await result.text());
}
async function denied(writes, auth = buyer) {
  const result = await commit(writes, auth);
  assert.equal(result.status, 403, await result.text());
}
const order = (id, overrides = {}) => ({id,userId:'buyer',customerName:'Buyer',phone:'0901234567',
  address:'Test',note:'',paymentMethod:'cash',isPaid:false,subtotal:100000,totalPrice:100000,
  pointsUsed:0,discountAmount:0,loyaltyAwarded:false,pointsRefunded:false,status:'completed',
  items:[{productId:7}],...overrides});
await allowed([write('orders/901',order(901)),write('orders/902',order(902,{status:'pending'})),
  write('loyaltyAccounts/buyer',{balance:100,lifetimeEarned:100})], 'owner');
const review = {userId:'buyer',orderId:901,itemIndex:0,rating:5,comment:'Ngon'};
await denied([write('products/7/reviews/901',review,{timestamp:'createdAt'})],other);
await denied([write('products/7/reviews/901',review,{timestamp:'createdAt'})],admin);
await denied([write('products/8/reviews/901',review,{timestamp:'createdAt'})]);
await denied([write('products/7/reviews/902',{...review,orderId:902},{timestamp:'createdAt'})]);
for (const invalid of [{rating:0},{rating:6},{rating:2.5},{comment:'x'.repeat(501)}, {itemIndex:-1}]) {
  await denied([write('products/7/reviews/901',{...review,...invalid},{timestamp:'createdAt'})]);
}
const simultaneous = await Promise.all([commit([write('products/7/reviews/901',review,{timestamp:'createdAt'})]),
  commit([write('products/7/reviews/901',review,{timestamp:'createdAt'})])]);
assert.deepEqual(simultaneous.map(r=>r.status).sort(),[200,403]);
await denied([{delete:path('products/7/reviews/901')}],admin);
console.log('PASS: verified reviews, validation, concurrent duplicate, immutable history');

const account = (balance, type, id, lifetime = 100) => ({balance,lifetimeEarned:lifetime,
  lastOrderId:id,lastMutationType:type,lastMutationKey:`${id}_${type}`});
const ledger = (id,type,points) => write(`loyaltyAccounts/buyer/transactions/${id}_${type}`,
  {orderId:id,type,points},{timestamp:'createdAt'});
await denied([write('loyaltyAccounts/buyer',account(999,'earn',901,999),{timestamp:'updatedAt'})]);
await denied([write('loyaltyAccounts/buyer',account(999,'earn',901,999),{timestamp:'updatedAt'})],admin);
await allowed([write('orders/905',order(905,{status:'pending'}))]);
await denied([write('orders/906',order(906,{status:'pending',pointsUsed:0.5,discountAmount:500,totalPrice:99500}))]);
await denied([write('orders/906',order(906,{status:'pending',pointsUsed:10,discountAmount:10000,totalPrice:90000})),
  write('loyaltyAccounts/buyer',account(90,'redeem',906),{timestamp:'updatedAt'})]);
await allowed([write('orders/903',order(903,{status:'pending',pointsUsed:10,discountAmount:10000,totalPrice:90000})),
  write('loyaltyAccounts/buyer',account(90,'redeem',903),{timestamp:'updatedAt'}),ledger(903,'redeem',10)]);
await denied([write('loyaltyAccounts/buyer',account(80,'redeem',903),{timestamp:'updatedAt'})]);
await denied([write('orders/903',{status:'cancelled',pointsRefunded:true},{mask:['status','pointsRefunded']})]);
await denied([write('loyaltyAccounts/buyer',account(100,'refund',903),{timestamp:'updatedAt'}),ledger(903,'refund',10)]);
await allowed([write('orders/903',{status:'cancelled',pointsRefunded:true},{mask:['status','pointsRefunded']}),
  write('loyaltyAccounts/buyer',account(100,'refund',903),{timestamp:'updatedAt'}),ledger(903,'refund',10)]);
await denied([write('loyaltyAccounts/buyer',account(110,'refund',903),{timestamp:'updatedAt'})]);
await denied([ledger(903,'refund',10)]);
await denied([write('loyaltyAccounts/buyer/transactions/903_refund',{points:500},{mask:['points']})],admin);
await allowed([write('orders/904',order(904,{status:'delivering'}))], 'owner');
await allowed([write('orders/904',{status:'completed',loyaltyAwarded:true},{mask:['status','loyaltyAwarded']}),
  write('loyaltyAccounts/buyer',account(110,'earn',904,110),{timestamp:'updatedAt'}),ledger(904,'earn',10)],admin);
await denied([write('loyaltyAccounts/buyer',account(120,'earn',904,120),{timestamp:'updatedAt'}),ledger(904,'earn',10)],admin);
const privateRead = await fetch(`${root}/loyaltyAccounts/buyer`,{headers:{Authorization:`Bearer ${other}`}});
assert.equal(privateRead.status,403);
await allowed([write('orders/907',order(907,{userId:'newbuyer',status:'delivering'}))], 'owner');
await allowed([
  write('orders/907',{status:'completed',loyaltyAwarded:true},{mask:['status','loyaltyAwarded']}),
  write('loyaltyAccounts/newbuyer',account(10,'earn',907,10),{timestamp:'updatedAt'}),
  write('loyaltyAccounts/newbuyer/transactions/907_earn',{orderId:907,type:'earn',points:10},{timestamp:'createdAt'}),
],admin);
await allowed([write('orders/908',order(908,{status:'delivering',subtotal:9000,totalPrice:9000})),
  write('orders/909',{id:909,userId:'buyer',status:'pending',totalPrice:15000})], 'owner');
await allowed([write('orders/908',{status:'completed',loyaltyAwarded:true},{mask:['status','loyaltyAwarded']})],admin);
await allowed([write('orders/909',{status:'cancelled'},{mask:['status']})]);
await allowed([write('users/buyer/favorites/7',{productId:7},{timestamp:'createdAt'})]);
await denied([write('users/buyer/favorites/8',{productId:8},{timestamp:'createdAt'})],other);
await allowed([{delete:path('users/buyer/favorites/7')}]);
console.log('PASS: redeem/refund/earn atomicity, replay prevention, balance spoofing, private accounts');
console.log('PASS: new account initialization, zero earnings, legacy cancellation, favorites ownership');
