#!/usr/bin/env python3
"""
Test script for SystemInfo class
"""

import asyncio
import json
from gptdiag.utils.system import SystemInfo


async def test_system_info():
    """Test the SystemInfo class."""
    print("🔍 Testing System Information Collection...")
    
    system_info = SystemInfo()
    
    # Test quick summary first (faster)
    print("\n📊 Quick Summary:")
    quick_summary = system_info.get_quick_summary()
    print(json.dumps(quick_summary, indent=2))
    
    # Test comprehensive async info
    print("\n🔧 Comprehensive System Info:")
    full_info = await system_info.get_async_info()
    
    # Pretty print key sections
    print("\n💻 CPU Info:")
    print(json.dumps(full_info.get("cpu", {}), indent=2))
    
    print("\n🧠 Memory Info:")
    print(json.dumps(full_info.get("memory", {}), indent=2))
    
    print("\n💾 Disk Info:")
    print(json.dumps(full_info.get("disk", [])[:2], indent=2))  # First 2 disks
    
    print("\n⚡ Top Processes:")
    processes = full_info.get("processes", [])
    for proc in processes[:5]:  # Top 5 processes
        print(f"  {proc['name']} (PID: {proc['pid']}) - CPU: {proc['cpu_percent']}%, MEM: {proc['memory_percent']}%")
    
    print("\n🔧 Failed Services:")
    services = full_info.get("services", [])
    if services:
        for service in services[:5]:  # First 5 failed services
            print(f"  {service['name']} - {service['active']} ({service['sub']})")
    else:
        print("  ✅ No failed services found!")
    
    print("\n⏰ System Uptime:")
    uptime = full_info.get("uptime", {})
    print(f"  {uptime.get('human_readable', 'Unknown')} ({uptime.get('days', 0)} days)")
    
    print("\n📈 Load Average:")
    load_avg = full_info.get("load_avg", {})
    print(f"  1min: {load_avg.get('1min', 0)}, 5min: {load_avg.get('5min', 0)}, 15min: {load_avg.get('15min', 0)}")
    print(f"  CPU cores: {load_avg.get('cpu_count', 0)}")
    
    print("\n✅ System monitoring test completed!")
    return full_info


if __name__ == "__main__":
    asyncio.run(test_system_info()) 