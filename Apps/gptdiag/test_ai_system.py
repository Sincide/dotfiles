#!/usr/bin/env python3
"""
Test AI analysis with real system data
"""

import asyncio
import json
from pathlib import Path
from gptdiag.utils.system import SystemInfo
from gptdiag.ai.manager import AIManager
from gptdiag.config.manager import ConfigManager


async def test_ai_system_analysis():
    """Test AI analysis with real system data."""
    print("🔍 Testing AI System Analysis with Real Data...")
    
    # Initialize components
    config_dir = Path.home() / ".config" / "gptdiag"
    config_manager = ConfigManager(config_dir)
    config = config_manager.get_ai_config()  # Get AI config dict
    ai_manager = AIManager(config)
    system_info = SystemInfo()
    
    # Initialize AI manager
    print("\n🤖 Initializing AI manager...")
    ai_initialized = await ai_manager.initialize()
    if not ai_initialized:
        print("❌ AI manager failed to initialize")
        return False
    
    # Get real system data
    print("\n📊 Collecting real system data...")
    system_data = await system_info.get_async_info()
    
    print("\n🤖 Requesting AI analysis...")
    try:
        # Request analysis from AI using the system health analysis method
        response = await ai_manager.analyze_system_health(system_data)
        
        if response.error:
            print(f"❌ AI Analysis failed: {response.error}")
            return False
        
        print(f"\n🎯 AI Analysis Results:")
        print("="*60)
        print(response.content)
        print("="*60)
        
        # Quick summary of what we tested
        print(f"\n✅ Test Results:")
        print(f"  • System data collected: {len(system_data)} categories")
        print(f"  • CPU Usage: {system_data['cpu']['percent']}%")
        print(f"  • Memory Usage: {system_data['memory']['percent']}%")
        print(f"  • Disk Usage: {system_data['disk'][0]['percent']}%")
        print(f"  • AI Analysis: {len(response.content)} characters")
        print(f"  • Model Used: {response.model_used}")
        print(f"  • Response Time: {response.response_time:.2f}s")
        
        return True
        
    except Exception as e:
        print(f"❌ AI Analysis failed: {e}")
        return False


async def test_quick_health_check():
    """Test a quick health check function."""
    print("\n🚀 Testing Quick Health Check...")
    
    system_info = SystemInfo()
    summary = system_info.get_quick_summary()
    
    # Simple health assessment
    health_status = "GOOD"
    alerts = []
    
    if summary["cpu_percent"] > 80:
        health_status = "WARNING"
        alerts.append(f"High CPU usage: {summary['cpu_percent']}%")
    
    if summary["memory_percent"] > 85:
        health_status = "CRITICAL"
        alerts.append(f"High memory usage: {summary['memory_percent']}%")
    
    if summary["disk_percent"] > 90:
        health_status = "CRITICAL"
        alerts.append(f"High disk usage: {summary['disk_percent']}%")
    
    print(f"  System Health: {health_status}")
    print(f"  Process Count: {summary['process_count']}")
    print(f"  Load Average: {summary['load_avg']:.2f}")
    
    if alerts:
        print(f"  Alerts: {', '.join(alerts)}")
    else:
        print(f"  ✅ No alerts - system running well!")
    
    return health_status, alerts


async def main():
    """Run all tests."""
    print("🎯 GPTDiag: AI + System Monitoring Integration Test")
    print("="*60)
    
    # Test 1: Quick health check
    health_status, alerts = await test_quick_health_check()
    
    # Test 2: Full AI analysis
    ai_success = await test_ai_system_analysis()
    
    print(f"\n🏁 Test Summary:")
    print(f"  Health Status: {health_status}")
    print(f"  Alerts: {len(alerts)}")
    print(f"  AI Analysis: {'✅ Success' if ai_success else '❌ Failed'}")
    print(f"\n🎉 Integration test completed!")


if __name__ == "__main__":
    asyncio.run(main()) 