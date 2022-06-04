
# L1D Read uncached

```json
{signal: [
  {name: 'clk',       wave: 'p.......'},
  {name: 'l1_stall',  wave: '01....0.'},
  {name: 'l1_read',   wave: '01.....0'},
  {name: 'l1_addr',   wave: 'x=.....x', data:["valid address"]},
  {name: "port_a_wea",wave: 'x0..10.x'},
  {name: "port_b_wea",wave: 'x0.....x'},
  {name: "disram_write",
   					  wave: 'x0..10.x'},
  {name: "cache_hit", wave: 'x0...1.x'},
  {name: "cache_out", wave: 'x=...=.x', data:["wrong", "valid"]},
  {name: 'read_stall',wave: 'x0...10x'},
  {name: "mmu_read",  wave: 'x1...0.x'},
  {name: "mmu_addr",  wave: 'x=.....x', data:["valid address"]},
  {name: "mmu_rdata", wave: 'x...=x.x', data:["valid"]},
  {name: "mmu_done",  wave: 'x0..10.x'},
]}
```

# L1D Write uncached

```json
{signal: [
  {name: 'clk',       wave: 'p......'},
  {name: 'l1_stall',  wave: 'x1...0x'},
  {name: 'l1_write',  wave: 'x1....x'},
  {name: 'l1_addr',   wave: 'x=....x', data:["valid address"]},
  {name: "port_a_we", wave: 'x0..10x'},
  {name: "port_b_we", wave: 'x0...1x'},
  {name: "disram_write",
   					  wave: 'x0..1.x'},
  {name: "cache_hit", wave: 'x0...1x'},
  {name: "cache_out", wave: 'x=...=x', data:["wrong", "valid"]},
  {name: 'read_stall',wave: 'x0....x'},
  {name: "mmu_read",  wave: 'x1...0x'},
  {name: "mmu_addr",  wave: 'x=....x', data:["valid address"]},
  {name: "mmu_rdata", wave: 'x...=xx', data:["valid"]},
  {name: "mmu_done",  wave: 'x0..10x'},
]}
```

# L1D Read dirty

```json
{signal: [
  {name: 'clk',       				wave: 'p..........'},
  {name: 'l1_stall',  				wave: '01.......0x'},
  {name: 'l1_read',   				wave: '01........x'},
  {name: 'l1_read_data',   			wave: 'x.......=.x', data:["valid"]},
  {name: 'l1_addr',   				wave: 'x=........x', data:["valid address"]},
  {name: "port_a_wea",				wave: 'x0.....10.x'},
  {name: "port_b_wea",				wave: 'x0........x'},
  {name: "disram_write",			wave: 'x0..10.10.x'},
  {},
  {name: "cache_dirty",				wave: 'x1...0....x'},
  {name: "cache_hit", 				wave: 'x0......1.x'},
  {name: "port_a_out",				wave: 'x=......=.x', data:["old","new"]},
  {name: "cache_out", 				wave: 'x=......=.x', data:["old","new"]},
  {name: "flush_dirty_set_mmu_write",
   									wave: 'xx1..0....x'},
  {},
  {name: "mmu_read",  				wave: 'x0...1..0.x'},
  {name: "mmu_write",  				wave: 'x01..0....x'},
  {name: "mmu_addr",  				wave: 'x=...=....x', data:["dirty address", "cache address"]},
  {name: "mmu_write_data", 			wave: 'x.=..x.x...', data:["valid"]},
  {name: "mmu_read_data", 			wave: 'x......=x..', data:["valid"]},
  {name: "mmu_done",  				wave: 'x0..10.10.x'},
]}
```
