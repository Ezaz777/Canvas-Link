import { getSeededIndex } from './src/utils/sync.ts';

function testShuffle() {
  const userId = 'test_user_123';
  const totalPins = 10;
  const epoch = new Date('2026-01-01T00:00:00Z').getTime();

  const results = new Set<number>();
  
  // Test a full cycle of 10 days
  for (let i = 0; i < totalPins; i++) {
    const date = new Date(epoch + i * 86400000);
    const dateStr = date.toISOString().split('T')[0];
    const index = getSeededIndex(dateStr, userId, totalPins);
    console.log(`Day ${i} (${dateStr}): Pin ${index}`);
    results.add(index);
  }
  
  console.log(`Unique pins in 10-day cycle: ${results.size} / ${totalPins}`);
  if (results.size === totalPins) {
    console.log('SUCCESS: All pins were used exactly once!');
  } else {
    console.error('FAILED: Some pins were repeated or missing.');
  }

  // Test the next cycle
  const nextResults = new Set<number>();
  for (let i = totalPins; i < totalPins * 2; i++) {
    const date = new Date(epoch + i * 86400000);
    const dateStr = date.toISOString().split('T')[0];
    const index = getSeededIndex(dateStr, userId, totalPins);
    nextResults.add(index);
  }
  console.log(`Unique pins in next 10-day cycle: ${nextResults.size} / ${totalPins}`);
}

testShuffle();
