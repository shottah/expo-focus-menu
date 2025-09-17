/**
 * Basic voice assistant integration for expo-focus-menu
 * This demonstrates how to add voice commands to control the focus menu
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
} from 'react-native';
import {
  VoiceAssistant,
  VoiceIntentBuilder,
  IntentCategory,
  ParameterType,
  PermissionStatus,
} from 'expo-assistant';

interface VoiceAssistantTestProps {
  onMenuAction?: (action: string) => void;
}

export function VoiceAssistantIntegration({ onMenuAction }: VoiceAssistantTestProps) {
  const [isInitialized, setIsInitialized] = useState(false);
  const [permissionStatus, setPermissionStatus] = useState<{
    microphone: PermissionStatus;
    speech: PermissionStatus;
  }>({
    microphone: PermissionStatus.UNDETERMINED,
    speech: PermissionStatus.UNDETERMINED,
  });
  const [lastVoiceCommand, setLastVoiceCommand] = useState<string>('');
  const [registeredIntents, setRegisteredIntents] = useState<string[]>([]);

  useEffect(() => {
    initializeVoiceAssistant();
  }, []);

  const initializeVoiceAssistant = async () => {
    try {
      const assistant = await VoiceAssistant.initialize({
        debugMode: true,
        enableBackgroundExecution: false,
      });

      // Create a search intent for menu items
      const searchMenuIntent = VoiceIntentBuilder
        .create<{ query: string }>()
        .withId('search-menu-items')
        .withCategory(IntentCategory.SEARCH)
        .requiredParameter('query', {
          type: ParameterType.STRING,
          prompt: 'What menu item would you like to find?',
        })
        .withHandler({
          handle: async (params) => {
            setLastVoiceCommand(`Search: ${params.query}`);

            // Simulate searching for menu items
            const menuItems = ['copy', 'share', 'edit', 'delete'];
            const found = menuItems.filter(item =>
              item.toLowerCase().includes(params.query.toLowerCase())
            );

            if (found.length > 0) {
              Alert.alert(
                'Menu Search',
                `Found ${found.length} item(s): ${found.join(', ')}`
              );
              return { success: true, data: found };
            }

            return {
              success: false,
              message: `No menu items found for "${params.query}"`
            };
          },
        })
        .configureIOS(ios =>
          ios.addSiriPhrase('Search focus menu for')
        )
        .build();

      // Create an action intent for menu operations
      const menuActionIntent = VoiceIntentBuilder
        .create<{ action: 'copy' | 'share' | 'edit' | 'delete' }>()
        .withId('menu-action')
        .withCategory(IntentCategory.PRODUCTIVITY)
        .requiredParameter('action', {
          type: ParameterType.ENUM,
          choices: ['copy', 'share', 'edit', 'delete'],
          prompt: 'Which action would you like to perform?',
        })
        .withHandler({
          handle: async (params) => {
            setLastVoiceCommand(`Action: ${params.action}`);

            if (onMenuAction) {
              onMenuAction(params.action);
            }

            Alert.alert(
              'Voice Command',
              `Executing "${params.action}" from voice command`
            );

            return {
              success: true,
              message: `${params.action} action performed`
            };
          },
        })
        .configureIOS(ios =>
          ios
            .addSiriPhrase('Focus menu action')
            .addSiriPhrase('Perform menu action')
        )
        .build();

      // Register intents
      await assistant.registerIntent(searchMenuIntent);
      await assistant.registerIntent(menuActionIntent);

      setRegisteredIntents(['search-menu-items', 'menu-action']);
      setIsInitialized(true);

      console.log('Voice Assistant initialized successfully');
    } catch (error) {
      console.error('Failed to initialize voice assistant:', error);
      Alert.alert('Voice Assistant Error', `Failed to initialize: ${error.message}`);
    }
  };

  const requestPermissions = async () => {
    try {
      const assistant = await VoiceAssistant.getInstance();

      const micStatus = await assistant.requestMicrophonePermission();
      const speechStatus = await assistant.requestSpeechRecognitionPermission();

      setPermissionStatus({
        microphone: micStatus,
        speech: speechStatus,
      });

      if (micStatus === PermissionStatus.GRANTED &&
          speechStatus === PermissionStatus.GRANTED) {
        Alert.alert('Success', 'Voice permissions granted!');
      } else {
        Alert.alert('Permissions', 'Some permissions were not granted');
      }
    } catch (error) {
      Alert.alert('Permission Error', `Failed to request permissions: ${error.message}`);
    }
  };

  const testVoiceCommand = async (command: string) => {
    try {
      const assistant = await VoiceAssistant.getInstance();

      // Simulate executing a voice command
      if (command === 'search') {
        await assistant.executeIntent('search-menu-items', { query: 'edit' });
      } else if (command === 'copy') {
        await assistant.executeIntent('menu-action', { action: 'copy' });
      } else if (command === 'share') {
        await assistant.executeIntent('menu-action', { action: 'share' });
      }
    } catch (error) {
      Alert.alert('Command Error', `Failed to execute command: ${error.message}`);
    }
  };

  const getStatusColor = (status: PermissionStatus) => {
    switch (status) {
      case PermissionStatus.GRANTED:
        return '#4CAF50';
      case PermissionStatus.DENIED:
        return '#F44336';
      case PermissionStatus.UNDETERMINED:
        return '#FF9800';
      default:
        return '#9E9E9E';
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Voice Assistant Integration</Text>

        <View style={styles.statusContainer}>
          <Text style={styles.label}>Status:</Text>
          <Text style={[
            styles.status,
            { color: isInitialized ? '#4CAF50' : '#F44336' }
          ]}>
            {isInitialized ? 'Initialized' : 'Not Initialized'}
          </Text>
        </View>

        <View style={styles.statusContainer}>
          <Text style={styles.label}>Registered Intents:</Text>
          <Text style={styles.value}>{registeredIntents.join(', ') || 'None'}</Text>
        </View>

        <View style={styles.statusContainer}>
          <Text style={styles.label}>Last Command:</Text>
          <Text style={styles.value}>{lastVoiceCommand || 'No commands yet'}</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Permissions</Text>

        <View style={styles.permissionRow}>
          <Text style={styles.label}>Microphone:</Text>
          <View style={[
            styles.permissionBadge,
            { backgroundColor: getStatusColor(permissionStatus.microphone) }
          ]}>
            <Text style={styles.permissionText}>
              {permissionStatus.microphone}
            </Text>
          </View>
        </View>

        <View style={styles.permissionRow}>
          <Text style={styles.label}>Speech Recognition:</Text>
          <View style={[
            styles.permissionBadge,
            { backgroundColor: getStatusColor(permissionStatus.speech) }
          ]}>
            <Text style={styles.permissionText}>
              {permissionStatus.speech}
            </Text>
          </View>
        </View>

        <TouchableOpacity
          style={styles.button}
          onPress={requestPermissions}
        >
          <Text style={styles.buttonText}>Request Permissions</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Test Voice Commands</Text>

        <TouchableOpacity
          style={styles.button}
          onPress={() => testVoiceCommand('search')}
        >
          <Text style={styles.buttonText}>Test: "Search for edit"</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => testVoiceCommand('copy')}
        >
          <Text style={styles.buttonText}>Test: "Copy action"</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => testVoiceCommand('share')}
        >
          <Text style={styles.buttonText}>Test: "Share action"</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.infoText}>
          Try saying:{'\n'}
          • "Hey Siri, search focus menu for copy"{'\n'}
          • "OK Google, perform menu action share"{'\n'}
          • "Hey Siri, focus menu action delete"
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  section: {
    backgroundColor: 'white',
    margin: 10,
    padding: 15,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    color: '#333',
  },
  statusContainer: {
    flexDirection: 'row',
    marginBottom: 10,
    alignItems: 'center',
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
    marginRight: 10,
    minWidth: 120,
  },
  status: {
    fontSize: 14,
    fontWeight: 'bold',
  },
  value: {
    fontSize: 14,
    color: '#333',
    flex: 1,
  },
  permissionRow: {
    flexDirection: 'row',
    marginBottom: 10,
    alignItems: 'center',
  },
  permissionBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 4,
  },
  permissionText: {
    color: 'white',
    fontSize: 12,
    fontWeight: 'bold',
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  infoText: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
  },
});