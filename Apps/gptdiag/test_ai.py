#!/usr/bin/env python3
"""
Test script for GPTDiag AI integration

Quick test to verify Ollama connectivity and AI functionality.
"""

import asyncio
import json
from pathlib import Path

# Add the gptdiag package to path
import sys
sys.path.insert(0, str(Path(__file__).parent))

from gptdiag.ai.manager import AIManager
from gptdiag.config.defaults import DEFAULT_AI_CONFIG


async def test_ollama_connection():
    """Test Ollama connection and basic functionality."""
    print("🧪 Testing GPTDiag AI Integration")
    print("=" * 50)
    
    # Initialize AI manager with default config
    ai_manager = AIManager(DEFAULT_AI_CONFIG)
    
    print("📡 Initializing AI providers...")
    if await ai_manager.initialize():
        print("✅ AI Manager initialized successfully!")
    else:
        print("❌ AI Manager failed to initialize")
        return
    
    # Get provider status
    print("\n📊 Provider Status:")
    status = await ai_manager.get_provider_status()
    print(json.dumps(status, indent=2, default=str))
    
    # Test system health analysis
    print("\n🔍 Testing System Health Analysis...")
    
    # Mock system data for testing
    test_system_data = {
        "cpu": {"percent": 45, "cores": 8},
        "memory": {"percent": 67, "used": 8.2, "total": 16.0},
        "disk": [{"device": "/dev/sda1", "percent": 78, "used": 120, "total": 500}],
        "processes": 156,
        "uptime": "2 days, 4 hours",
        "load_avg": [1.2, 1.4, 1.1]
    }
    
    try:
        response = await ai_manager.analyze_system_health(test_system_data)
        
        print(f"\n🤖 AI Response:")
        print(f"Model Used: {response.model_used}")
        print(f"Response Time: {response.response_time:.2f}s" if response.response_time else "Response Time: N/A")
        print(f"Tokens Used: {response.tokens_used}" if response.tokens_used else "Tokens: N/A")
        
        if response.error:
            print(f"❌ Error: {response.error}")
        else:
            print(f"✅ Success!")
            print(f"\n📝 Analysis Result:")
            print("-" * 40)
            print(response.content)
            print("-" * 40)
        
    except Exception as e:
        print(f"❌ Test failed with exception: {e}")
    
    # Clean up
    print("\n🧹 Cleaning up...")
    await ai_manager.close()
    print("✅ Test completed!")


async def test_model_roles():
    """Test different model roles."""
    print("\n🎭 Testing Model Roles...")
    print("=" * 50)
    
    ai_manager = AIManager(DEFAULT_AI_CONFIG)
    
    if not await ai_manager.initialize():
        print("❌ Failed to initialize AI manager")
        return
    
    # Test different types of requests
    test_cases = [
        {
            "name": "Quick CPU Check",
            "data": {"cpu": 95, "load": [5.2, 4.8, 4.5]},
            "expected_model": "qwen3:4b"  # Fast diagnostics model
        },
        {
            "name": "General System Analysis", 
            "data": {"cpu": 45, "memory": 67, "disk": 78},
            "expected_model": "phi4:latest"  # General analysis model
        }
    ]
    
    for test_case in test_cases:
        print(f"\n🧪 Testing: {test_case['name']}")
        
        try:
            response = await ai_manager.analyze_system_health(test_case["data"])
            print(f"Model Used: {response.model_used}")
            print(f"Expected: {test_case['expected_model']}")
            
            if response.error:
                print(f"❌ Error: {response.error}")
            else:
                print(f"✅ Success! Response length: {len(response.content)} chars")
                
        except Exception as e:
            print(f"❌ Failed: {e}")
    
    await ai_manager.close()


if __name__ == "__main__":
    print("🚀 Starting GPTDiag AI Integration Tests")
    
    try:
        # Run basic connection test
        asyncio.run(test_ollama_connection())
        
        # Run model role tests
        asyncio.run(test_model_roles())
        
    except KeyboardInterrupt:
        print("\n⚠️  Tests interrupted by user")
    except Exception as e:
        print(f"\n❌ Test suite failed: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n🏁 Test suite finished") 