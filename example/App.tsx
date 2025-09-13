import React, { useState } from 'react';
import {
  Alert,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { ExpoFocusMenuView, FocusMenuItem } from 'expo-focus-menu';

export default function App() {
  const [lastAction, setLastAction] = useState<string>('No action yet');
  const [selectedEmoji, setSelectedEmoji] = useState<string>('');

  // Basic menu items with emojis
  const basicMenuItems: FocusMenuItem[] = [
    { id: 'copy', title: 'Copy', icon: 'doc.on.doc' },
    { id: 'paste', title: 'Paste', icon: 'doc.on.clipboard' },
    { id: 'delete', title: 'Delete', icon: 'trash', destructive: true },
  ];

  const handleMenuItemPress = (itemId: string) => {
    setLastAction(`Menu: ${itemId}`);
    Alert.alert('Menu Action', `Selected: ${itemId}`);
  };

  const handleReactionPress = (data: { emoji: string; selected: boolean }) => {
    const { emoji, selected } = data;
    if (selected) {
      setSelectedEmoji(emoji);
      setLastAction(`Reaction: ${emoji}`);
    } else {
      setSelectedEmoji('');
      setLastAction(`Deselected: ${emoji}`);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
        <Text style={styles.header}>Expo Focus Menu with Emojis</Text>

        <View style={styles.statusContainer}>
          <Text style={styles.statusLabel}>Last Action:</Text>
          <Text style={styles.statusValue}>{lastAction}</Text>
          <Text style={styles.statusLabel}>Selected Emoji:</Text>
          <Text style={styles.statusValue}>{selectedEmoji || 'None'}</Text>
        </View>

        {/* Default Emoji Reactions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Default Emoji Reactions</Text>
          <ExpoFocusMenuView
            items={basicMenuItems}
            onItemPress={handleMenuItemPress}
            showReactions={true}
            reactions={['😀', '❤️', '👍', '🔥', '💯', '🎉']}
            onReactionPress={handleReactionPress}
            hapticFeedback={true}
          >
            <View style={styles.menuTarget}>
              <Text style={styles.menuTargetText}>React to this!</Text>
              <Text style={styles.menuTargetHint}>Long press for menu & reactions</Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        {/* Different Emoji Sets */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Fun Emojis</Text>
          <ExpoFocusMenuView
            items={basicMenuItems}
            onItemPress={handleMenuItemPress}
            showReactions={true}
            reactions={['👀', '🚀', '✨', '🙏', '💜', '😂']}
            onReactionPress={handleReactionPress}
            hapticFeedback={true}
          >
            <View style={styles.menuTarget}>
              <Text style={styles.menuTargetText}>Fun Reactions</Text>
              <Text style={styles.menuTargetHint}>Different emoji set</Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        {/* Art & Music Emojis */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Art & Music</Text>
          <ExpoFocusMenuView
            items={basicMenuItems}
            onItemPress={handleMenuItemPress}
            showReactions={true}
            reactions={['🎨', '🎭', '🎪', '🎯', '🎲', '🎸']}
            onReactionPress={handleReactionPress}
            hapticFeedback={true}
          >
            <View style={styles.menuTarget}>
              <Text style={styles.menuTargetText}>Creative</Text>
              <Text style={styles.menuTargetHint}>Art and music emojis</Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        {/* Nature Emojis */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Nature</Text>
          <ExpoFocusMenuView
            items={basicMenuItems}
            onItemPress={handleMenuItemPress}
            showReactions={true}
            reactions={['🌱', '🌿', '🍀', '🌳', '🌲', '🌴']}
            onReactionPress={handleReactionPress}
            hapticFeedback={true}
          >
            <View style={styles.menuTarget}>
              <Text style={styles.menuTargetText}>Nature</Text>
              <Text style={styles.menuTargetHint}>Nature emojis</Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        {/* Message-like interface with reactions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Message Reactions</Text>
          <ExpoFocusMenuView
            items={[
              { id: 'reply', title: 'Reply', icon: 'arrowshape.turn.up.left' },
              { id: 'forward', title: 'Forward', icon: 'arrowshape.turn.up.right' },
              { id: 'copy', title: 'Copy', icon: 'doc.on.doc' },
              { id: 'delete', title: 'Delete', icon: 'trash', destructive: true },
            ]}
            onItemPress={handleMenuItemPress}
            showReactions={true}
            reactions={['❤️', '👍', '😂', '😮', '😢', '😡']}
            onReactionPress={handleReactionPress}
            hapticFeedback={true}
          >
            <View style={styles.messageContainer}>
              <Text style={styles.messageText}>
                This is a sample message that you can react to with emojis!
              </Text>
              <Text style={styles.messageTime}>10:30 AM</Text>
            </View>
          </ExpoFocusMenuView>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 50,
  },
  header: {
    fontSize: 28,
    fontWeight: 'bold',
    textAlign: 'center',
    marginVertical: 20,
    color: '#333',
  },
  statusContainer: {
    backgroundColor: '#fff',
    marginHorizontal: 20,
    padding: 15,
    borderRadius: 10,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusLabel: {
    fontSize: 12,
    color: '#666',
    marginTop: 5,
  },
  statusValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 5,
  },
  section: {
    marginHorizontal: 20,
    marginBottom: 25,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 10,
    color: '#333',
  },
  menuTarget: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 80,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  menuTargetText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 5,
  },
  menuTargetHint: {
    fontSize: 12,
    color: '#666',
  },
  messageContainer: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 12,
    maxWidth: '80%',
    alignSelf: 'flex-start',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
  },
  messageText: {
    fontSize: 15,
    color: '#333',
    lineHeight: 20,
  },
  messageTime: {
    fontSize: 11,
    color: '#999',
    marginTop: 5,
  },
});