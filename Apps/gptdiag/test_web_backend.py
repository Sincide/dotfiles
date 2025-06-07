#!/usr/bin/env python3
"""
Test script for GPTDiag Web Backend

Tests that the FastAPI backend correctly wraps the existing core engine
and provides working API endpoints.
"""

import asyncio
import aiohttp
import json
import time
from pathlib import Path

async def test_web_backend():
    """Test all web backend endpoints."""
    base_url = "http://localhost:8000"
    
    print("🧪 Testing GPTDiag Web Backend")
    print("=" * 50)
    
    # Wait for server startup
    print("⏳ Waiting for server to start...")
    await asyncio.sleep(2)
    
    async with aiohttp.ClientSession() as session:
        
        # Test 1: Health Check
        print("\n1. Testing health check endpoint...")
        try:
            async with session.get(f"{base_url}/") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"   ✅ Service: {data['service']}")
                    print(f"   ✅ Status: {data['status']}")
                    print(f"   ✅ AI Available: {data['ai_available']}")
                else:
                    print(f"   ❌ Health check failed: {response.status}")
                    return False
        except Exception as e:
            print(f"   ❌ Health check error: {e}")
            return False
        
        # Test 2: System Summary
        print("\n2. Testing system summary endpoint...")
        try:
            async with session.get(f"{base_url}/api/system/summary") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"   ✅ CPU: {data['cpu_percent']:.1f}%")
                    print(f"   ✅ Memory: {data['memory_percent']:.1f}%")
                    print(f"   ✅ Disk: {data['disk_percent']:.1f}%")
                    print(f"   ✅ Processes: {data['process_count']}")
                    print(f"   ✅ Load Avg: {data['load_avg']:.2f}")
                    
                    if data['alerts']:
                        print(f"   ⚠️  Alerts: {len(data['alerts'])}")
                        for alert in data['alerts']:
                            print(f"      - {alert}")
                    else:
                        print("   ✅ No alerts")
                else:
                    print(f"   ❌ System summary failed: {response.status}")
                    return False
        except Exception as e:
            print(f"   ❌ System summary error: {e}")
            return False
        
        # Test 3: Detailed System Info
        print("\n3. Testing detailed system info endpoint...")
        try:
            async with session.get(f"{base_url}/api/system/detailed") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"   ✅ System info keys: {list(data.keys())}")
                    print(f"   ✅ CPU cores: {data.get('cpu', {}).get('cores', 'N/A')}")
                    print(f"   ✅ Memory total: {data.get('memory', {}).get('total_gb', 'N/A')} GB")
                    print(f"   ✅ Processes count: {len(data.get('processes', []))}")
                else:
                    print(f"   ❌ Detailed info failed: {response.status}")
                    return False
        except Exception as e:
            print(f"   ❌ Detailed info error: {e}")
            return False
        
        # Test 4: AI Analysis
        print("\n4. Testing AI analysis endpoint...")
        try:
            ai_request = {
                "custom_prompt": "Provide a brief system health summary",
                "model_role": "diagnostics"
            }
            
            print("   ⏳ Requesting AI analysis... (this may take 20-30 seconds)")
            start_time = time.time()
            
            async with session.post(
                f"{base_url}/api/ai/analyze",
                json=ai_request,
                timeout=aiohttp.ClientTimeout(total=60)
            ) as response:
                
                processing_time = time.time() - start_time
                
                if response.status == 200:
                    data = await response.json()
                    print(f"   ✅ Analysis completed in {processing_time:.1f}s")
                    print(f"   ✅ Model used: {data['model_used']}")
                    print(f"   ✅ Tokens used: {data['tokens_used']}")
                    print(f"   ✅ Analysis length: {len(data['analysis'])} characters")
                    print(f"   ✅ First 200 chars: {data['analysis'][:200]}...")
                elif response.status == 503:
                    print("   ⚠️  AI analysis not available (no AI providers)")
                else:
                    print(f"   ❌ AI analysis failed: {response.status}")
                    error_text = await response.text()
                    print(f"      Error: {error_text}")
        except asyncio.TimeoutError:
            print("   ⚠️  AI analysis timed out (>60s)")
        except Exception as e:
            print(f"   ❌ AI analysis error: {e}")
    
    print("\n" + "=" * 50)
    print("🎉 Web backend testing completed!")
    print("\n💡 Next steps:")
    print("   1. Visit http://localhost:8000 in your browser")
    print("   2. Try the API endpoints manually")
    print("   3. Test WebSocket connection for real-time updates")
    
    return True


async def test_websocket():
    """Test WebSocket real-time updates."""
    import websockets
    
    print("\n5. Testing WebSocket connection...")
    try:
        uri = "ws://localhost:8000/ws/updates"
        async with websockets.connect(uri) as websocket:
            
            # Wait for initial data
            initial_data = await websocket.recv()
            data = json.loads(initial_data)
            print(f"   ✅ Initial data received: {data['type']}")
            
            # Send ping
            await websocket.send(json.dumps({"type": "ping"}))
            
            # Wait for pong
            pong_response = await websocket.recv()
            pong_data = json.loads(pong_response)
            if pong_data.get("type") == "pong":
                print("   ✅ Ping-pong successful")
            
            # Wait for a real-time update
            print("   ⏳ Waiting for real-time update...")
            update_data = await asyncio.wait_for(websocket.recv(), timeout=10)
            update = json.loads(update_data)
            if update.get("type") == "system_update":
                print("   ✅ Real-time update received")
                print(f"      CPU: {update['data']['cpu_percent']:.1f}%")
            
    except ImportError:
        print("   ⚠️  WebSocket test skipped (websockets library not available)")
        print("   📦 Install with: sudo pacman -S python-websockets")
    except Exception as e:
        print(f"   ❌ WebSocket test error: {e}")


async def main():
    """Main test function."""
    print("🌐 GPTDiag Web Backend Test Suite")
    print("\n📋 Prerequisites:")
    print("   1. Run: cd Apps/gptdiag && python -m gptdiag.web.server")
    print("   2. Or: python -m gptdiag web --dev")
    print("   3. Server should be running on http://localhost:8000")
    
    input("\n⏸️  Press Enter when server is running...")
    
    # Test HTTP endpoints
    success = await test_web_backend()
    
    if success:
        # Test WebSocket
        await test_websocket()
    
    print("\n🏁 Testing complete!")


if __name__ == "__main__":
    asyncio.run(main()) 